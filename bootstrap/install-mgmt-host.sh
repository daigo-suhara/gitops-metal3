#!/bin/bash
set -euo pipefail

# 1. minikube のインストール (未インストールの場合)
if ! command -v minikube &> /dev/null; then
    echo "Installing minikube..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
fi

# 2. クラスターの削除と再構築 (driver=none でホストネットワーク直結)
sudo minikube delete || true
sudo minikube start --driver=none --kubernetes-version=v1.31.0

# 3. Argo CDのインストール
sudo kubectl create namespace argocd || true
sudo kubectl apply -k bootstrap/

# 4. Root Appの適用
sudo kubectl apply -f bootstrap/root-app.yaml

echo "=== minikube (driver=none) is ready ==="
echo "Argo CD: https://localhost"
