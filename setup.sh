#!/bin/bash

marzban_dir="~/Marzban-node"

apt update -y
apt upgrade -y
apt install curl socat git -y

# install docker
# Add Docker's official GPG key:
apt install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the docker repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update

apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# allow for running docker rootless
sudo usermod -aG docker $USER
newgrp docker

# install marzban-node
cd
git clone https://github.com/Gozargah/Marzban-node ${marzban_dir}
mkdir /var/lib/marzban-node
cd ${marzban_dir}

cat >docker-compose.yml <<EOL
services:
  marzban-node:
    # build: .
    image: gozargah/marzban-node:latest
    restart: always
    network_mode: host

    environment:
      SSL_CLIENT_CERT_FILE: "/var/lib/marzban-node/ssl_client_cert.pem"

    volumes:
      - /var/lib/marzban-node:/var/lib/marzban-node
EOL

marzban_cert_file="/var/lib/marzban-node/ssl_client_cert.pem"
touch /var/lib/marzban-node/ssl_client_cert.pem
echo Created file ${marzban_cert_file}
echo Copy the certificate from the Marzban panel and paste it in ${marzban_cert_file}
echo Then, run "docker compose up -d" from the directory ${marzban_dir}
