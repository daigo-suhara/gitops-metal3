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
管理ホスト（Ubuntu 等）で Docker, Kind, kubectl, Helm をインストールします。
```bash
sudo bash bootstrap/install-mgmt-host.sh
```

### 2. 管理クラスタ (Kind) の起動
```bash
kind create cluster --config bootstrap/kind-cluster.yaml
```

### 3. GitOps の起動
ArgoCD をインストールし、このレポジトリの同期を開始します。**イメージのダウンロードは Ironic 起動時に自動的に行われます。**

```bash
kubectl apply -f bootstrap/root-app.yaml
```

---

## 自動化されている事項
- **OS イメージ**: Ironic  起動時に Fedora CoreOS と TinyIPA を自動取得。
- **ブートモード**: 全ホスト `UEFI` 統一。
- **形式**: Fedora CoreOS + Ignition による堅牢な初期化。
- **ネットワーク**: Ironic DHCP によるゲートウェイ・DNS の配布。
- **VIP**: `kube-vip` によるコントロールプレーン VIP 管理。
