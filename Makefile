export KUBECONFIG ?= /tmp/homelab-kubeconfig

.PHONY: help
help:
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*##/ - /'

.PHONY: seal-cloudflared-token
seal-cloudflared-token: ## usage: make seal-cloudflared-token TOKEN=<cloudflare-token>
	@test -n "$(TOKEN)" || (echo "TOKEN is required. usage: make $@ TOKEN=xxx" && exit 1)
	@kubectl create secret generic cloudflared-tunnel-token \
		--namespace cloudflare --dry-run=client -o yaml \
		--from-literal=token='$(TOKEN)' \
		| kubeseal -o yaml > homelab/cloudflared/tunnel-token-sealed.yaml
	@echo "→ homelab/cloudflared/tunnel-token-sealed.yaml written. commit & push to deploy."

.PHONY: seal-dcloud-database
seal-dcloud-database: ## usage: make seal-dcloud-database PASSWORD=<postgres-password>
	@test -n "$(PASSWORD)" || (echo "PASSWORD is required. usage: make $@ PASSWORD=xxx" && exit 1)
	@kubectl create secret generic dcloud-database \
		--namespace dcloud-system --dry-run=client -o yaml \
		--from-literal=password='$(PASSWORD)' \
		--from-literal=postgres-password='$(PASSWORD)' \
		--from-literal=repmgr-password='$(PASSWORD)' \
		--from-literal=sr-check-password='$(PASSWORD)' \
		--from-literal=admin-password='$(PASSWORD)' \
		--from-literal=DCLD_DATABASE_URL='postgresql://dcloud:$(PASSWORD)@dcloud-postgresql-ha-pgpool:5432/dcloud?sslmode=disable' \
		--from-literal=DCLD_DATABASE_MIGRATION_URL='postgresql://dcloud:$(PASSWORD)@dcloud-postgresql-ha-postgresql:5432/dcloud?sslmode=disable' \
		| kubeseal -o yaml > homelab/dcloud-secret/dcloud-database-sealed.yaml
	@echo "→ homelab/dcloud-secret/dcloud-database-sealed.yaml written. commit & push to deploy."

# --- sealed-secrets master key backup/restore -------------------------------
#
# The workload cluster's sealed-secrets controller generates a fresh keypair
# on first boot. Rebuilding the cluster (or wiping kube-system Secrets) means
# every SealedSecret in git becomes undecryptable. These targets snapshot the
# active keypair to the mgmt node, and restore it into a rebuilt workload so
# all existing SealedSecrets keep unsealing to the same plaintext.

BACKUP_HOST ?= mgmt
BACKUP_USER ?= ubuntu
BACKUP_DIR  ?= /home/ubuntu/backups
BACKUP_FILE ?= sealed-secrets-master-key.yaml

.PHONY: backup-sealed-key
backup-sealed-key: ## snapshot the active sealed-secrets keypair to $(BACKUP_HOST):$(BACKUP_DIR)
	@ssh $(BACKUP_USER)@$(BACKUP_HOST) 'mkdir -p $(BACKUP_DIR) && chmod 700 $(BACKUP_DIR)'
	@kubectl -n kube-system get secret \
		-l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml \
		| ssh $(BACKUP_USER)@$(BACKUP_HOST) 'cat > $(BACKUP_DIR)/$(BACKUP_FILE) && chmod 600 $(BACKUP_DIR)/$(BACKUP_FILE)'
	@echo "→ backed up to $(BACKUP_HOST):$(BACKUP_DIR)/$(BACKUP_FILE)"

.PHONY: restore-sealed-key
restore-sealed-key: ## apply the backed-up keypair to the current KUBECONFIG cluster; run BEFORE app-of-apps
	@ssh $(BACKUP_USER)@$(BACKUP_HOST) 'cat $(BACKUP_DIR)/$(BACKUP_FILE)' \
		| kubectl -n kube-system apply -f -
	@kubectl -n kube-system rollout restart deploy sealed-secrets-controller
	@echo "→ key applied, controller restarted; existing SealedSecrets will unseal on next reconcile."
