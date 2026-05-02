# GitOps Metal3 Bare-Metal Deployment

このレポジトリは、Metal3、Cluster API (CAPI)、および ArgoCD を使用して、ベアメタル環境に Kubernetes クラスタを自動デプロイするための GitOps 定義です。

## クラスタ構成
- **Management Cluster**: Kind (Docker 上で稼働)
- **Workload Cluster**: Bare-Metal サーバー (Ubuntu 24.04)
- **Networking**:
  - **VIP**: 172.16.10.10 (kube-vip による管理)
  - **LoadBalancer**: MetalLB (172.16.10.201 - 172.16.10.250)
  - **CNI**: Cilium

---

## 構築手順 (Step-by-Step)

### 1. ホストマシンの準備
管理ホスト（Ubuntu 等）で以下のツールをインストールします。
- Docker
- Kind
- kubectl
- Helm

```bash
# スクリプトを利用する場合
sudo bash bootstrap/install-mgmt-host.sh
```

### 2. イメージファイルの準備 (重要)
Metal3 が物理マシンに OS を書き込むためのイメージファイルを準備し、Kind ノード内に転送します。

```bash
# ホスト側でディレクトリ作成
mkdir -p /tmp/images
cd /tmp/images

# TinyIPA (起動用エージェント) のダウンロード
curl -Lo ironic-python-agent.kernel https://tarballs.openstack.org/ironic-python-agent/tinyipa/files/tinyipa-master.vmlinuz
curl -Lo ironic-python-agent.initramfs https://tarballs.openstack.org/ironic-python-agent/tinyipa/files/tinyipa-master.gz

# Ubuntu OS イメージの準備 (適切な qcow2 イメージを配置)
# 例: ubuntu-24.04.qcow2
```

### 3. 管理クラスタ (Kind) の起動
```bash
kind create cluster --config bootstrap/kind-cluster.yaml
```

### 4. イメージの Kind ノードへの転送
Kind の `hostPath` マウントの制限を回避するため、ファイルを物理的に Kind ノードコンテナ内にコピーします。

```bash
docker exec metal3-mgmt-control-plane mkdir -p /var/images
docker cp /tmp/images/. metal3-mgmt-control-plane:/var/images/
```

### 5. GitOps の起動
ArgoCD をインストールし、このレポジトリの同期を開始します。

```bash
kubectl apply -f bootstrap/root-app.yaml
```

---

## 自動化されている修正事項
以下の項目は Git 上の YAML に反映済みのため、自動的に適用されます：
- **ブートモード**: 全ホスト `UEFI` 統一。
- **クリーニング**: スタック防止のため `automatedCleaningMode: disabled`。
- **K8s インストール**: `preKubeadmCommands` によるパッケージ自動インストール。
- **ネットワーク**: Ironic DHCP によるゲートウェイ・DNS の配布。
- **VIP**: `kube-vip` のブートストラップモード設定。
- **CNI**: Cilium の API サーバー直接指定設定。

---

## トラブルシューティング

### Q: プロビジョニングが `Cleaning failed` で止まる
- **原因**: 物理マシンのディスク消去に失敗。
- **対策**: `hardware/bmh-tx1320-01.yaml` の `automatedCleaningMode` が `disabled` であることを確認してください。

### Q: API サーバーに接続できない (Connection refused)
- **原因**: `kube-vip` が VIP (172.16.10.10) を上げていない可能性があります。
- **対策**: 対象ノードに SSH し、`/etc/kubernetes/manifests/kube-vip.yaml` に `admin.conf` のマウントがあるか確認してください。

### Q: ノードが `NotReady` のまま
- **原因**: Cilium が API サーバー (10.96.0.1) に接続できていない。
- **対策**: 物理ノードで `10.96.0.1:443` を `127.0.0.1:6443` にリダイレクトする iptables 設定を確認してください。
```bash
sudo iptables -t nat -A OUTPUT -d 10.96.0.1 -p tcp --dport 443 -j DNAT --to-destination 127.0.0.1:6443
```
