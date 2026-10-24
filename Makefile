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

welcome: ## Deploy the onboarding welcome app to https://links.test
	@kubectl apply -f bootstrap/welcome-app/manifests.yaml
	@echo "Waiting for welcome-app rollout..."
	@kubectl rollout status deployment welcome-app -n welcome-app --timeout=60s
	@echo "Welcome app is live at https://links.test"

clean-welcome: ## Delete the temporary welcome app and its namespace
	@kubectl delete -f bootstrap/welcome-app/manifests.yaml --ignore-not-found=true

tunnel: ## Start minikube tunnel (requires sudo; binds ingress/loadbalancers to localhost)
	@minikube tunnel

ingress-forward: ## Forward ingress controller to localhost (80 & 443) for Windows host access
	@echo "Forwarding Ingress Controller to localhost:80 and localhost:443..."
	@sudo KUBECONFIG=$$HOME/.kube/config kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 80:80 443:443 --address 0.0.0.0

status: ## Show Minikube and pod status
	@minikube status || true
	@kubectl get nodes -o wide || true
	@kubectl get pods -A || true

sync-kubeconfig: ## Export flattened kubeconfig from WSL2 to Windows host (%USERPROFILE%\.kube\config)
	@mkdir -p /mnt/c/Users/$$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')/.kube
	@kubectl config view --minify --flatten > /mnt/c/Users/$$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')/.kube/config
	@echo "Kubeconfig successfully synced to Windows host (%USERPROFILE%\.kube\config)"

stop: ## Stop Minikube cluster
	@minikube stop

clean: ## Destroy Minikube cluster
	@minikube delete
