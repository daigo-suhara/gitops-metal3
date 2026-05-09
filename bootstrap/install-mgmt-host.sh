#!/bin/bash
set -euo pipefail

# 1. Kindクラスターの作成
kind create cluster --config bootstrap/kind-cluster.yaml

# 2. Argo CDのインストール
kubectl create namespace argocd
kubectl apply -k bootstrap/

# 3. Root Appの適用 (これですべてのアプリが動き出す)
kubectl apply -f bootstrap/root-app.yaml

echo "=== Done. Waiting for Argo CD... ==="
