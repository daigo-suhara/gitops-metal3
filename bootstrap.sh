#!/bin/bash
set -eo pipefail

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

echo "Installing ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for ArgoCD..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data":{"kustomize.buildOptions":"--enable-helm"}}'

echo "Applying App-of-Apps..."
kubectl apply -f argocd/app-of-apps.yaml

echo "Bootstrap complete!"
