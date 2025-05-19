#!/bin/bash
mkdir -p shared_data

CONTAINERS=("mpi-node1" "mpi-node2" "mpi-node3")
USERNAME="mpiuser"
SHARED_DIR="/home/${USERNAME}/mpi-data"
HOSTFILE="./shared_data/host_file"
LOCAL_SHARED_DIR="$(pwd)/shared_data"

echo "[*] 启动容器..."
docker-compose up -d --build

echo "[*] 等待容器启动..."
sleep 5

echo "[*] 修复共享目录权限并创建目录..."
mkdir -p "$LOCAL_SHARED_DIR"
docker exec -u root "${CONTAINERS[0]}" bash -c "mkdir -p $SHARED_DIR && chown -R $USERNAME:$USERNAME $SHARED_DIR"
# 共享目录在所有容器同样路径，权限也同步，通常 Docker 绑定卷自动同步权限

echo "[*] 在第一个容器中生成 SSH 密钥对（无密码）..."
docker exec -u $USERNAME "${CONTAINERS[0]}" bash -c "rm -rf ~/.ssh && mkdir -p ~/.ssh && chmod 700 ~/.ssh"
docker exec -u $USERNAME "${CONTAINERS[0]}" bash -c "ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa"

echo "[*] 获取第一个容器的公钥..."
PUB_KEY=$(docker exec -u $USERNAME "${CONTAINERS[0]}" cat /home/${USERNAME}/.ssh/id_rsa.pub)

echo "[*] 分发公钥到所有容器的 authorized_keys..."
for container in "${CONTAINERS[@]}"; do
  docker exec -u $USERNAME "$container" bash -c "mkdir -p /home/${USERNAME}/.ssh && \
    echo '$PUB_KEY' > /home/${USERNAME}/.ssh/authorized_keys && \
    chmod 600 /home/${USERNAME}/.ssh/authorized_keys && \
    chmod 700 /home/${USERNAME}/.ssh && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh"
done

echo "[*] 配置 SSH 免密登录相关 SSH 配置，关闭 HostKey 检查..."
for container in "${CONTAINERS[@]}"; do
  docker exec -u $USERNAME "$container" bash -c "echo -e 'Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null' > /home/${USERNAME}/.ssh/config && chmod 600 /home/${USERNAME}/.ssh/config"
done

echo "[*] 创建 host_file 文件..."
rm -f $HOSTFILE
for container in "${CONTAINERS[@]}"; do
  echo "$container" >> $HOSTFILE
done

echo "[*] Hostfile 内容如下："
cat $HOSTFILE

echo "[*] 验证 SSH 连接..."
for container in "${CONTAINERS[@]}"; do
  docker exec -u $USERNAME "${CONTAINERS[0]}" ssh -o BatchMode=yes -o ConnectTimeout=5 "$container" hostname
done

echo "[+] 配置完成！现在你可以用下面命令运行 MPI 程序了："
echo "mpirun --hostfile host_file -np 3 ./your_mpi_program"

#启动容器mpi-node1，并进入home目录
docker exec -it -u mpiuser mpi-node1 bash -c "cd ~; exec bash"
