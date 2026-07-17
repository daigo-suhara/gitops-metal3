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
