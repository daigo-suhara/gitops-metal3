#!/bin/bash
set -euo pipefail

# どの環境でもリポジトリルートを基準に動作させる
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 設定
IMAGE_DIR="/home/ubuntu/ironic-images/html/images"
K8S_VERSION="v1.35.4"
BUILD_DIR="$ROOT_DIR/image-builder"
CAPIC_DIR="$BUILD_DIR/images/capi"
IMAGE_NAME="ubuntu-2404-kube-${K8S_VERSION}.raw"

# 1. Image Builder の取得
if [ ! -d "$BUILD_DIR" ]; then
    git clone https://github.com/kubernetes-sigs/image-builder.git "$BUILD_DIR"
fi

# 2. ビルドの実行
cd "$CAPIC_DIR"

# requirements.yml の場所を動的に見つけてインストール
REQ_FILE=$(find . -name "requirements.yml" | head -n 1)
if [ -n "$REQ_FILE" ]; then
    ansible-galaxy install -r "$REQ_FILE" -p ansible/roles/ --force
fi

# ビルド実行 (既存のイメージがあればスキップするオプションも検討できるが、明示的なビルドを優先)
if [ ! -f "output/$IMAGE_NAME" ]; then
    make build-node-raw-ubuntu-2404 KUBERNETES_VERSION="$K8S_VERSION"
    # ビルド後のファイル名を固定化
    GENERATED_IMAGE=$(find output -name "*.raw" | head -n 1)
    mv "$GENERATED_IMAGE" "output/$IMAGE_NAME"
fi

# 3. 配置
if [ -f "output/$IMAGE_NAME" ]; then
    sha256sum "output/$IMAGE_NAME" > "output/${IMAGE_NAME}.sha256"
    sudo mkdir -p "$IMAGE_DIR"
    sudo cp "output/$IMAGE_NAME" "output/${IMAGE_NAME}.sha256" "$IMAGE_DIR/"
    sudo chmod 644 "$IMAGE_DIR/$IMAGE_NAME" "$IMAGE_DIR/${IMAGE_NAME}.sha256"
    echo "Image deployed to $IMAGE_DIR/$IMAGE_NAME"
else
    echo "Build failed: Image not found."
    exit 1
fi
