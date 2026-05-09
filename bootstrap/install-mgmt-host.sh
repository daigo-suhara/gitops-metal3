#!/bin/bash
set -euo pipefail

# 1. k3s のインストール
# --write-kubeconfig-mode 644 は、一般ユーザーでも kubectl を使いやすくするためです
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

# KUBECONFIG の設定 (現在のセッション用)
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# 2. Argo CDのインストール
kubectl create namespace argocd || true
kubectl apply -k bootstrap/

# 3. Root Appの適用
kubectl apply -f bootstrap/root-app.yaml

echo "=== k3s setup complete ==="
echo "Argo CD: https://localhost"
