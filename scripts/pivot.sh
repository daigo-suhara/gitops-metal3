#!/usr/bin/env bash
set -euo pipefail

SOURCE_KUBECONFIG="${SOURCE_KUBECONFIG:-${KUBECONFIG:-$HOME/.kube/config}}"
TARGET_KUBECONFIG="${TARGET_KUBECONFIG:-$HOME/.kube/homelab-kubeconfig}"
CLUSTER_NAME="${CLUSTER_NAME:-homelab}"
CLUSTER_NAMESPACE="${CLUSTER_NAMESPACE:-metal3}"

command -v clusterctl >/dev/null || { echo "clusterctl is required" >&2; exit 1; }
command -v kubectl >/dev/null || { echo "kubectl is required" >&2; exit 1; }

echo "Waiting for the workload kubeconfig..."
for _ in {1..60}; do
  if clusterctl get kubeconfig "$CLUSTER_NAME" \
      --kubeconfig "$SOURCE_KUBECONFIG" \
      --namespace "$CLUSTER_NAMESPACE" >"$TARGET_KUBECONFIG" 2>/dev/null; then
    chmod 600 "$TARGET_KUBECONFIG"
    break
  fi
  sleep 30
done

test -s "$TARGET_KUBECONFIG" || {
  echo "workload kubeconfig was not created" >&2
  exit 1
}

echo "Waiting for Argo CD on the workload cluster..."
kubectl --kubeconfig "$TARGET_KUBECONFIG" -n argocd \
  wait --for=condition=available deployment/argocd-server --timeout=600s

echo "Moving Cluster API resources to the workload cluster..."
clusterctl move \
  --kubeconfig "$SOURCE_KUBECONFIG" \
  --to-kubeconfig "$TARGET_KUBECONFIG" \
  --namespace "$CLUSTER_NAMESPACE" \
  -v 5

echo "Restoring the bootstrap App-of-Apps on the workload cluster..."
kubectl --kubeconfig "$TARGET_KUBECONFIG" apply -f bootstrap/app-of-apps.yaml

echo "Pivot complete."
