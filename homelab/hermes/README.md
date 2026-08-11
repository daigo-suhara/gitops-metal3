# Hermes: fully local personal AI

`llama.cpp` runs the quantized Qwen2.5 7B Instruct model on the workload cluster's
CPUs. Hermes connects to it through the cluster-internal `llama-cpp` Service;
no inference request leaves the cluster.

The first start downloads the model into the `llama-cpp-models` PVC. It can
take several minutes, and the `llama-cpp` startup probe intentionally allows
15 minutes for this. Subsequent restarts load the cached model from Ceph.

## Use

After Argo CD has synced the `hermes` application and both Deployments are
ready, open `http://172.16.100.132` from the LAN. The initial credentials are
`admin` / `admin`; change them in `kustomization.yaml` and push the change.
Kustomize changes the generated Secret name, so Argo CD rolls Hermes to pick
up the new credentials automatically.

The terminal UI is also available from your workstation:

```sh
make hermes-chat
```

The UI shares the persistent `/opt/data` volume with the gateway, so memories,
skills, cron jobs, and sessions survive Pod restarts.

## Operations

```sh
make hermes-status # Pods, PVCs, and Services
make hermes-logs   # llama.cpp startup and model-download progress
```

The dashboard is the only externally reachable Service and is limited to the
LAN by its Cilium L2 LoadBalancer IP. The model server is reachable only as
`llama-cpp.hermes.svc.cluster.local:8080` inside the cluster, and Hermes only
as `hermes.hermes.svc.cluster.local:8642`.
