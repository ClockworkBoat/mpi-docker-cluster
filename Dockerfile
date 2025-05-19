FROM ubuntu:22.04

# 安装必要软件包
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    openssh-server \
    openmpi-bin \
    libopenmpi-dev \
    iputils-ping \
    vim && \
    mkdir -p /var/run/sshd && \
    rm -rf /var/lib/apt/lists/*

# 创建用户 mpiuser 并设置密码
RUN useradd -ms /bin/bash mpiuser && echo "mpiuser:mpiuser" | chpasswd

# 允许密码登录
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 设置 ssh 权限目录
RUN mkdir -p /home/mpiuser/.ssh && \
    chown mpiuser:mpiuser /home/mpiuser/.ssh && \
    chmod 700 /home/mpiuser/.ssh

# 启动 ssh 服务
CMD ["/usr/sbin/sshd", "-D"]

