#!/bin/bash
set -eux
export DEBIAN_FRONTEND=noninteractive

install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /' \
  > /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/stable:/v1.36/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/v1.36/deb/ /' \
  > /etc/apt/sources.list.d/cri-o.list

apt-get update
apt-get install -y cri-o kubelet=1.36.2-2.1 kubeadm=1.36.2-2.1 kubectl=1.36.2-2.1
apt-mark hold kubelet kubeadm kubectl
systemctl enable --now crio
systemctl enable kubelet

printf 'br_netfilter\noverlay\n' > /etc/modules-load.d/k8s.conf
modprobe br_netfilter overlay
printf 'net.bridge.bridge-nf-call-iptables=1\nnet.ipv4.ip_forward=1\nnet.bridge.bridge-nf-call-ip6tables=1\n' \
  > /etc/sysctl.d/k8s.conf
sysctl --system
