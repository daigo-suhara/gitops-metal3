# GitOps Metal3 Bare-Metal Deployment

このレポジトリは、Metal3、Cluster API (CAPI)、および ArgoCD を使用して、ベアメタル環境に Kubernetes クラスタを自動デプロイするための GitOps 定義です。

## アーキテクチャ

本構成では、**Hierarchical ArgoCD (階層型ArgoCD)** パターンを採用し、インフラ管理とワークロード管理の責任を明確に分離しています。

1.  **Management ArgoCD (管理クラスタ側)**:
    *   物理サーバ (BareMetalHost) のプロビジョニング
    *   ワークロードクラスタ (CAPI Cluster) のライフサイクル管理
    *   ワークロードクラスタへの **Workload ArgoCD** のインストール
2.  **Workload ArgoCD (ワークロードクラスタ側)**:
    *   自分自身のクラスタ内のアドオン (Cilium, MetalLB, Ceph) の管理
    *   アプリケーションのデプロイ

### フォルダ構成

```text
.
├── system/                 # 管理クラスタ自体の基盤
│   ├── base/               # BMO, Ironic, CAPI プロバイダーの実体
│   └── argocd-apps/        # 管理側 ArgoCD が担当する基本アプリ
├── workload-clusters/      # ワークロードクラスタの定義
│   └── prod/
│       ├── infrastructure/ # 物理サーバ (BMH) とクラスタ (CAPI) の定義
│       ├── management-apps/# 管理側 ArgoCD が prod クラスタを管理するための定義
│       │                   # (クラスタ作成 + ワークロード側 ArgoCD のインストール)
│       └── apps/           # ワークロード側 ArgoCD が自分自身を管理するディレクトリ
│                           # (Cilium, MetalLB, アプリケーション)
└── bootstrap/              # 管理ホストのセットアップと root-app の起動
```

## クラスタ構成
- **Management Cluster**: Kind (Docker 上で稼働)
- **Workload Cluster**: Bare-Metal サーバー (Ubuntu 24.04 Noble)
- **Networking**:
  - **Control Plane VIP**: 172.16.10.100 (kube-vip スタンドアロン ARP モード)
  - **LoadBalancer**: MetalLB (172.16.10.201 - 172.16.10.250)
  - **CNI**: Cilium

---

## 構築手順 (Step-by-Step)

### 1. 管理ホストの準備
管理ホスト（Ubuntu 等）で Docker, Kind, kubectl, Helm をインストールします。
```bash
sudo bash bootstrap/install-mgmt-host.sh
```

### 2. 管理クラスタ (Kind) の起動
```bash
kind create cluster --config bootstrap/kind-cluster.yaml
```

### 3. GitOps の起動
管理側の ArgoCD を起動し、全ての自動構築をスタートさせます。
```bash
kubectl apply -f bootstrap/root-app.yaml
```

---

## 自動化・堅牢化のポイント
- **全自動 HA 構築**: `kube-vip` を API サーバーへの依存なしに起動させることで、初期構築時の「卵と鶏」問題を解消。
- **UUID 自動同期**: ノードの `kubeadm join` 時に `metal3.io/uuid` ラベルを自動付与し、CAPI との紐付けを自動化。
- **RBAC 自動配布**: `ClusterResourceSet (CRS)` により、管理クラスタからワークロードクラスタのヘルスチェックに必要な権限を自動注入。
- **ベアメタル・ライフサイクル**: Ironic による OS (Ubuntu 24.04) の書き込みから Kubernetes のセットアップまで完全自動化。
