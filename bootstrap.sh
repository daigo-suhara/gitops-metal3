#!/bin/bash
set -euo pipefail

kind create cluster --config bootstrap/kind-cluster.yaml
kubectl apply -k bootstrap/
kubectl apply -f argocd/app-of-apps.yaml
