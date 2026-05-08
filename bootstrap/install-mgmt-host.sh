#!/bin/bash
# Bootstrap host setup: Docker + kind + kubectl + helm
# Run as root (sudo bash install-mgmt-host.sh)
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y ca-certificates curl git make qemu-utils qemu-system-x86 snapd
snap install packer --classic
apt-get install -y python3-pip
pip3 install ansible --break-system-packages

# Docker official repo
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
usermod -aG docker ubuntu

ARCH=$(dpkg --print-architecture)

# kind
curl -Lo /usr/local/bin/kind "https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-${ARCH}"
chmod +x /usr/local/bin/kind

# kubectl
KUBECTL_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -Lo /tmp/kubectl "https://dl.k8s.io/release/${KUBECTL_VER}/bin/linux/${ARCH}/kubectl"
install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
rm -f /tmp/kubectl

# helm
HELM_VER=v3.15.4
curl -fsSL "https://get.helm.sh/helm-${HELM_VER}-linux-${ARCH}.tar.gz" | tar -xzf - -C /tmp
install -m 0755 "/tmp/linux-${ARCH}/helm" /usr/local/bin/helm
rm -rf "/tmp/linux-${ARCH}"

# 自動ビルド実行
chmod +x "$(dirname "$0")/build-and-deploy.sh"
"$(dirname "$0")/build-and-deploy.sh"

echo "=== versions ==="
docker --version
kind --version
kubectl version --client
helm version --short

echo ""
echo "=== DONE ==="
echo "ubuntu user is now in docker group. SSH session will pick this up on next login."
