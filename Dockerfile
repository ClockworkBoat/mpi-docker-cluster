FROM ubuntu:22.04

# 安装必要软件
RUN apt-get update && apt-get install -y \
    openssh-server \
    mpich \
    iputils-ping \
    vim \
    && mkdir /var/run/sshd

# 创建用户mpiuser并设置密码
RUN useradd -ms /bin/bash mpiuser && echo "mpiuser:mpiuser" | chpasswd

# 允许密码登录（方便调试，生产可禁用）
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 设置ssh免密登录需要目录和权限
RUN mkdir /home/mpiuser/.ssh && chown mpiuser:mpiuser /home/mpiuser/.ssh && chmod 700 /home/mpiuser/.ssh

# 容器启动时启动SSH服务
CMD ["/usr/sbin/sshd", "-D"]

