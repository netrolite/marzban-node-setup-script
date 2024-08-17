#!/bin/bash

marzban_dir="~/marzban-node"
marzban_cert_file="/var/lib/marzban-node/ssl_client_cert.pem"
node_exporter_dir="~/node-exporter"
node_exporter_port=55000

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

# pull marzban docker image
docker pull gozargah/marzban-node:latest

# install neovim
apt install neovim -y

mkdir -p /var/lib/marzban-node
touch ${marzban_cert_file}
echo Created file ${marzban_cert_file}

mkdir ${marzban_dir}
cd ${marzban_dir}

cat > docker-compose.yml <<EOL
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

docker pull gozargah/marzban-node:latest

# install node exporter for prometheus monitoring
mkdir ${node_exporter_dir}
cd ${node_exporter_dir}

cat > docker-compose.yml <<EOL
services:
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "${node_exporter_port}:9100"  # Expose the Node Exporter port
    volumes:
      - /proc:/host/proc:ro  # Mount the host's /proc directory
      - /sys:/host/sys:ro    # Mount the host's /sys directory
      - /:/host/root:ro      # Mount the host's root filesystem
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/host/root'
EOL

# start node exporter
docker compose up -d

echo Copy the certificate from the Marzban panel and paste it in ${marzban_cert_file}
echo Then, run "docker compose up -d" from the directory ${marzban_dir}

