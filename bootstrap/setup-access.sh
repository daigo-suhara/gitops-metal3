#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

# 依存パッケージのインストール
sudo apt-get update
sudo apt-get install -y ca-certificates curl git make qemu-utils qemu-system-x86 python3-pip unzip

# Argo CD への localhost アクセスを有効化 (バックグラウンド転送)
# ポート 8080 を argocd-server の 443 にマップ
if kubectl get svc argocd-server -n argocd > /dev/null 2>&1; then
    echo "Setting up Argo CD access on localhost:8080..."
    # 既存のプロセスがあれば終了させる
    pkill -f "port-forward svc/argocd-server" || true
    nohup kubectl port-forward svc/argocd-server -n argocd --address 0.0.0.0 8080:443 > /dev/null 2>&1 &
fi

echo "=== Argo CD is available at https://localhost:8080 ==="
echo "=== DONE ==="
