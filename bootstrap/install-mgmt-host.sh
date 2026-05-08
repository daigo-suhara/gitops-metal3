#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

# 依存パッケージのインストール
apt-get update
apt-get install -y ca-certificates curl git make qemu-utils qemu-system-x86 snapd python3-pip unzip
pip3 install ansible --break-system-packages --break-system-packages

# リポジトリルートを確定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# ビルドスクリプトを実行可能に
chmod +x "$SCRIPT_DIR/build-and-deploy.sh"

# 共有ディレクトリの作成
sudo mkdir -p /home/ubuntu/ironic-images/html/images
sudo chmod -R 777 /home/ubuntu/ironic-images

# 最後に自動ビルドを実行
"$SCRIPT_DIR/build-and-deploy.sh"

echo "=== DONE ==="
