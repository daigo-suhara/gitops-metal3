# GitOps Metal3 Bare-Metal Deployment

このレポジトリは、Metal3 と Cluster API (CAPI) を使って、ベアメタル環境に Kubernetes クラスタを自動デプロイするための定義です。

## アーキテクチャ

`bootstrap.sh` が管理クラスタ上で必要な基盤を順番に入れます。

1. `clusterctl init` で CAPI / CAPM3 をインストール
2. `system/ironic` の最小 overlay で Bare Metal Operator と Ironic を適用
3. `hardware` と `cluster` を適用してワークロードクラスタを作成

### フォルダ構成

```text
.
├── system/
│   └── ironic/             # Metal3 / Ironic の最小 overlay
├── cluster/                # ワークロードクラスタの Cluster / ControlPlane / MachineDeployment
├── hardware/               # BareMetalHost 定義
```
`bootstrap.sh` はローカル起動のまとめスクリプトです。

## クラスタ構成
- **Management Cluster**: MicroK8s
- **Cluster**: Bare-Metal サーバー (Ubuntu 24.04 Noble)
- **Networking**:
  - **Control Plane VIP**: 172.16.10.100 (kube-vip スタンドアロン ARP モード)
  - **LoadBalancer**: MetalLB (172.16.10.201 - 172.16.10.250)
  - **CNI**: Cilium

---

## 構築手順 (Step-by-Step)

前提: `microk8s`, `kubectl` が入っていること。

### 0. ノードイメージの作成
GitHub Actions の `Build CAPI image` を手動実行すると、`image-builder` で `ubuntu-2404-kube-v1.35.raw` を作成し、GHCR に OCI artifact としてアップロードします。

GitHub Actions では `GITHUB_TOKEN` を使って `ghcr.io/daigo-suhara/gitops-metal3/ubuntu-2404-kube-v1.35:latest` に push します。

GHCR の package は public にしておく必要があります。CAPI の `Metal3MachineTemplate` は `oci://ghcr.io/daigo-suhara/gitops-metal3/ubuntu-2404-kube-v1.35:latest` を直接参照して、Ironic の HTTP キャッシュを使わずに OS イメージを取得します。

### 1. 管理クラスタと Metal3 の起動
管理クラスタに CAPI / Metal3 を直接インストールします。
```bash
./bootstrap.sh
```
