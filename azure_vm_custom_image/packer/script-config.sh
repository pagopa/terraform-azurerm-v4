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

### install zip unzip ca-certificates curl wget apt-transport-https lsb-release gnupg jq
export DEBIAN_FRONTEND=noninteractive
apt-get clean
rm -rf /var/lib/apt/lists/*
apt-get -y update
sleep 3
apt-get -y --allow-unauthenticated install zip unzip ca-certificates curl wget apt-transport-https lsb-release gnupg jq

check_command "zip"
check_command "unzip"
check_command "jq"

### AZ CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

check_command "az"


### KUBECTL
# https://kubernetes.io/releases/
# https://github.com/Azure/kubelogin/releases
# Define variables
KUBECTL_VERSION="${KUBECTL_VERSION:-1.31.5}"
KUBELOGIN_VERSION="${KUBELOGIN_VERSION:-0.1.7}"
az aks install-cli --client-version "${KUBECTL_VERSION}" --kubelogin-version "${KUBELOGIN_VERSION}"
check_command "kubectl"
check_command "kubelogin"

sleep 3
apt-get -y install python3-pip

check_command "python3"

### Packer
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null && \
sudo apt-get update && \
sudo apt-get install -y packer

check_command "packer"

