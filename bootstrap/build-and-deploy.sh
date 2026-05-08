#!/bin/bash
set -euo pipefail

# どの環境でもリポジトリルートを基準に動作させる
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# 設定
IMAGE_DIR="/var/www/html/images"
K8S_VERSION="v1.35.4"
BUILD_DIR="$ROOT_DIR/image-builder"
CAPIC_DIR="$BUILD_DIR/images/capi"

# 1. Image Builder の取得
if [ ! -d "$BUILD_DIR" ]; then
    git clone https://github.com/kubernetes-sigs/image-builder.git "$BUILD_DIR"
fi

# 2. ビルドの実行
cd "$CAPIC_DIR"
# 最新のAnsible roleを取得
ansible-galaxy install -r ansible/requirements.yml || true

# ビルド実行
make build-node-raw-ubuntu-2404 KUBERNETES_VERSION="$K8S_VERSION"

# 3. 配置
RAW_IMAGE="output/ubuntu-2404/ubuntu-2404-kube-${K8S_VERSION}.raw"
if [ -f "$RAW_IMAGE" ]; then
    sha256sum "$RAW_IMAGE" > "${RAW_IMAGE}.sha256"
    sudo mkdir -p "$IMAGE_DIR"
    sudo cp "$RAW_IMAGE" "${RAW_IMAGE}.sha256" "$IMAGE_DIR/"
    echo "Image deployed to $IMAGE_DIR"
else
    echo "Build failed: Image not found at $RAW_IMAGE"
    exit 1
fi
