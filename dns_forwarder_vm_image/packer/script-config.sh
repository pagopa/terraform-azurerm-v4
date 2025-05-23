#!/usr/bin/env bash
set -euo pipefail

function check_command(){
  if command -v "$1";
  then
    echo "✅ $1 installed"
  else
    echo "❌ $1 NOT installed"
    exit 1
  fi
}

# install zip unzip ca-certificates curl wget apt-transport-https lsb-release gnupg jq
export DEBIAN_FRONTEND=noninteractive
apt-get clean
rm -rf /var/lib/apt/lists/*
apt-get -y update
apt-get -y update
sleep 3
apt-get -y --allow-unauthenticated install zip unzip ca-certificates curl wget apt-transport-https lsb-release gnupg jq

check_command "zip"
check_command "unzip"
check_command "jq"

# setup DOCKER installation from https://docs.docker.com/engine/install/ubuntu/
curl -fsSL https://download.docker.com/linux/ubuntu/gpg |
    gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get -y update
sleep 3
apt-get -y install  python3-pip

check_command "python3"

# DOCKER & DOCKER COMPOSE
apt-get -y --allow-unauthenticated install docker-ce docker-ce-cli containerd.io docker-compose-plugin

check_command "docker"

# install YQ from https://github.com/mikefarah/yq#install
YQ_VERSION="v4.45.1"
YQ_BINARY="yq_linux_amd64"
wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}.tar.gz -O - |\
  tar xz && mv ${YQ_BINARY} /usr/bin/yq

check_command "yq"

docker compose pull
echo "✅ docker pulled image before disable dns forwarder default"

echo "🚀 prepare to run dns forwarder"

# disabled ubuntu internal dns resolver to allow coredns to connecto to port 53
sudo systemctl stop systemd-resolved && sudo systemctl disable systemd-resolved
echo "✅ systemd-resolved disabled, port 53 free"

cd /home/packer || exit
docker compose up -d || exit

nc -zv localhost 53
echo "✅ TCP 53 ok!"
nc -zvu localhost 53
echo "✅ UDP 53 ok!"

echo "✅ dns forwarder running"

# prepare machine for k6 large load test
sysctl -w net.ipv4.ip_local_port_range="1024 65535"
sysctl -w net.ipv4.tcp_tw_reuse=1
sysctl -w net.ipv4.tcp_timestamps=1
ulimit -n 250000
