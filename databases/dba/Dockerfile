FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y openssh-server sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash fueros && \
    echo 'fueros:fueros' | chpasswd && \
    usermod -aG sudo fueros && \
    echo 'fueros ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    mkdir -p /var/run/sshd && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

COPY install_postgres.sh /usr/local/bin/install_postgres.sh
RUN chmod +x /usr/local/bin/install_postgres.sh && \
    /usr/local/bin/install_postgres.sh

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 22 5432

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]