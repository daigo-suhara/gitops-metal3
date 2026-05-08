#!/bin/bash
set -euxo pipefail

# 設定
BUILD_DIR="/tmp/image-builder-build"
IRONIC_SERVER="root@172.16.10.50"
IRONIC_PATH="/var/www/html/images/"
IMAGE_NAME="custom-k8s-v1.35.4.raw"

# 1. Image Builder のクローンとビルド
rm -rf $BUILD_DIR
git clone https://github.com/kubernetes-sigs/image-builder.git $BUILD_DIR
cd $BUILD_DIR/images/capi
# K8s v1.35 向けにビルド
make build-node-raw-ubuntu-2404

# 2. チェックサム計算
RAW_IMAGE="output/ubuntu-2404/ubuntu-2404-kube-v1.35.4.raw"
sha256sum "$RAW_IMAGE" > "${RAW_IMAGE}.sha256"

# 3. Ironic サーバーへ転送
scp "$RAW_IMAGE" "${RAW_IMAGE}.sha256" $IRONIC_SERVER:$IRONIC_PATH

# 4. マニフェストの URL 更新 (Metal3 の controlplane.yaml)
MANIFEST_PATH="/Users/daigo-suhara/src/metal3/workload-clusters/prod/infrastructure/cluster/manifests/controlplane.yaml"
sed -i "s|url: http://.*|url: http://172.16.10.50:6180/images/$IMAGE_NAME|g" $MANIFEST_PATH
sed -i "s|checksum: http://.*|checksum: http://172.16.10.50:6180/images/$IMAGE_NAME.sha256|g" $MANIFEST_PATH

echo "Image build and deployment complete."
