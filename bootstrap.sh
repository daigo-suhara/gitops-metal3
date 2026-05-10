#!/bin/bash
set -euo pipefail

tmp_kind_config="$(mktemp)"
trap 'rm -f "$tmp_kind_config"' EXIT
cat >"$tmp_kind_config" <<'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: metal3-mgmt
networking:
  apiServerAddress: "0.0.0.0"
  apiServerPort: 6443
  podSubnet: "10.244.0.0/16"
  serviceSubnet: "10.96.0.0/12"
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
      - containerPort: 6385
        hostPort: 6385
        protocol: TCP
      - containerPort: 5050
        hostPort: 5050
        protocol: TCP
      - containerPort: 6180
        hostPort: 6180
        protocol: TCP
EOF

kind create cluster --config "$tmp_kind_config"

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.13.0/manifests/install.yaml
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data":{"kustomize.buildOptions":"--enable-helm"}}'
kubectl apply -f argocd/app-of-apps.yaml
