#!/bin/bash
set -eo pipefail

CLUSTERCTL_VERSION="v1.13.1"
CAPI_VERSION="v1.13.1"
CAPM3_VERSION="v1.13.0"

if ! command -v microk8s &> /dev/null; then
    echo "Installing MicroK8s..."
    sudo snap install microk8s --classic
    sudo usermod -a -G microk8s $USER
    sudo chown -f -R $USER ~/.kube
    
    echo "Waiting for MicroK8s to be ready..."
    sudo microk8s status --wait-ready
    
    echo "Enabling addons..."
    sudo microk8s enable dns storage rbac
fi

if ! command -v kubectl &> /dev/null; then
    sudo snap alias microk8s.kubectl kubectl
fi

mkdir -p ~/.kube
sudo microk8s config > ~/.kube/config
chmod 600 ~/.kube/config
export KUBECONFIG=~/.kube/config

ensure_clusterctl() {
    if command -v clusterctl &> /dev/null; then
        return
    fi

    local arch
    case "$(uname -m)" in
        x86_64|amd64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        *)
            echo "Unsupported architecture for clusterctl: $(uname -m)"
            exit 1
            ;;
    esac

    local tmpdir
    tmpdir="$(mktemp -d)"
    curl -fL -o "${tmpdir}/clusterctl" "https://github.com/kubernetes-sigs/cluster-api/releases/download/${CLUSTERCTL_VERSION}/clusterctl-linux-${arch}"
    sudo install -m 0755 "${tmpdir}/clusterctl" /usr/local/bin/clusterctl
}

wait_for_deployments() {
    local namespace="$1"
    kubectl -n "$namespace" wait --for=condition=Available deployment --all --timeout=600s
}

echo "Ensuring clusterctl is installed..."
ensure_clusterctl

export EXP_CLUSTER_RESOURCE_SET=true
export EXP_KUBEADM_BOOTSTRAP_FORMAT_IGNITION=true

echo "Initializing Cluster API and Metal3..."
clusterctl init \
  --core "cluster-api:${CAPI_VERSION}" \
  --bootstrap "kubeadm:${CAPI_VERSION}" \
  --control-plane "kubeadm:${CAPI_VERSION}" \
  --infrastructure "metal3:${CAPM3_VERSION}"

echo "Applying Bare Metal Operator and Ironic..."
kubectl apply -k system/ironic

echo "Waiting for Cluster API and Metal3 components..."
wait_for_deployments capi-system
wait_for_deployments capi-kubeadm-bootstrap-system
wait_for_deployments capi-kubeadm-control-plane-system
wait_for_deployments capm3-system
wait_for_deployments metal3

echo "Applying hardware inventory and cluster resources..."
kubectl apply -k hardware
kubectl apply -k cluster

echo "Bootstrap complete!"
