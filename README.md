# GitOps Metal3 Bare-Metal Deployment

このレポジトリは、Metal3、Cluster API (CAPI)、および ArgoCD を使用して、ベアメタル環境に Kubernetes クラスタを自動デプロイするための GitOps 定義です。

## アーキテクチャ

本構成では、**Hierarchical ArgoCD (階層型ArgoCD)** パターンを採用し、インフラ管理とワークロード管理の責任を分離しています。各コンポーネントは、必要最小限のディレクトリに整理しています。

1.  **Management ArgoCD (管理クラスタ側)**:
    *   物理サーバ (BareMetalHost) のプロビジョニング
    *   クラスタ (CAPI Cluster) のライフサイクル管理
    *   クラスタへの **Workload ArgoCD** の自動インストール
2.  **Workload ArgoCD (クラスタ側)**:
    *   自分自身のクラスタ内のアドオン (Cilium, MetalLB, Ceph) の管理
    *   アプリケーションのデプロイ
### フォルダ構成

```text
.
├── argocd/                 # app-of-apps と子アプリ定義
├── system/
│   ├── capi/               # CAPI Provider 定義
│   └── ironic/             # Metal3 / Ironic 本体
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
GitHub Actions の `Build CAPI image` を手動実行すると、`image-builder` で `ubuntu-2404-kube-v1.35.qcow2` を作成し、GitHub Releases にアップロードします。

Ironic はその Release asset を起動時に取得し、`http://172.16.0.10:6180/images/` にキャッシュします。

### 1. 管理クラスタと GitOps の起動
管理側の ArgoCD とアプリ群を起動します。
```bash
./bootstrap.sh
```
