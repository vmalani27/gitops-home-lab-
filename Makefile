SHELL := /bin/bash
.PHONY: help prereqs start stop status certs clean

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

prereqs: ## Install tools inside Ubuntu WSL2 (docker, minikube, kubectl, helm, mkcert)
	@chmod +x bootstrap/*.sh
	@./bootstrap/install-prereqs.sh

start: ## Start Minikube cluster with tuned specs and ingress addon
	@chmod +x bootstrap/*.sh
	@./bootstrap/start-minikube.sh

certs: ## Generate wildcard certificates and inject into Kubernetes secrets
	@chmod +x bootstrap/*.sh
	@./bootstrap/setup-certs.sh

status: ## Show Minikube and pod status
	@minikube status || true
	@kubectl get nodes -o wide || true
	@kubectl get pods -A || true

stop: ## Stop Minikube cluster
	@minikube stop

clean: ## Destroy Minikube cluster
	@minikube delete
