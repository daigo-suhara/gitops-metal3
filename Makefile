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
