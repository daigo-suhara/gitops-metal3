# GitOps Metal3 Bare-Metal Deployment

このレポジトリは、Metal3、Cluster API (CAPI)、および ArgoCD を使用して、ベアメタル環境に Kubernetes クラスタを自動デプロイするための GitOps 定義です。

## アーキテクチャ

本構成では、**Hierarchical ArgoCD (階層型ArgoCD)** パターンを採用し、インフラ管理とワークロード管理の責任を明確に分離しています。また、各コンポーネントは「自己完結型アプリフォルダ」形式で整理されています。

1.  **Management ArgoCD (管理クラスタ側)**:
    *   物理サーバ (BareMetalHost) のプロビジョニング
    *   ワークロードクラスタ (CAPI Cluster) のライフサイクル管理
    *   ワークロードクラスタへの **Workload ArgoCD** の自動インストール
2.  **Workload ArgoCD (ワークロードクラスタ側)**:
    *   自分自身のクラスタ内のアドオン (Cilium, MetalLB, Ceph) の管理
    *   アプリケーションのデプロイ
### フォルダ構成

```text
.
├── argocd/                 # app-of-apps と子アプリ定義
├── cluster/                # ワークロードクラスタの Cluster / ControlPlane / MachineDeployment
├── hardware/               # BareMetalHost 定義
├── system/                 # 管理クラスタ自体の基盤 (BMO, ArgoCD設定, CAPI等)
└── workload-clusters/      # 既存のワークロード向け定義 (移行中の互換レイアウト)
```
`bootstrap/` は管理ホストのセットアップ用スクリプト群、`bootstrap.sh` はローカル起動のまとめスクリプトです。

## クラスタ構成
- **Management Cluster**: Kind (Docker 上で稼働)
- **Workload Cluster**: Bare-Metal サーバー (Ubuntu 24.04 Noble)
- **Networking**:
  - **Control Plane VIP**: 172.16.10.100 (kube-vip スタンドアロン ARP モード)
  - **LoadBalancer**: MetalLB (172.16.10.201 - 172.16.10.250)
  - **CNI**: Cilium

---

## 構築手順 (Step-by-Step)

### 1. 管理クラスタと GitOps の起動
管理側の ArgoCD とアプリ群を起動します。
```bash
./bootstrap.sh
```

### 2. 必要に応じて ArgoCD にアクセス
```bash
bash bootstrap/setup-access.sh
```
