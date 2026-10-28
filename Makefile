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

bootstrap: prereqs start certs welcome sync-kubeconfig ## One-command full setup: install tools, boot cluster, inject certs, deploy welcome app
	@echo ""
	@echo "================================================================="
	@echo "Bootstrap complete!"
	@echo "Add the following line to your hosts file if not already present:"
	@echo "127.0.0.1  links.test"
	@echo ""
	@echo "To forward ingress traffic on Windows / WSL2, run in a terminal:"
	@echo "make ingress-forward   (or: minikube tunnel)"
	@echo ""
	@echo "Then visit: https://links.test"
	@echo "================================================================="

certs: ## Generate wildcard certificates and inject into Kubernetes secrets
	@chmod +x bootstrap/*.sh
	@./bootstrap/setup-certs.sh

welcome: ## Deploy the onboarding welcome app to https://links.test
	@kubectl create namespace welcome-app --dry-run=client -o yaml | kubectl apply -f -
	@kubectl create configmap welcome-html --from-file=index.html=bootstrap/welcome-app/html/index.html -n welcome-app --dry-run=client -o yaml | kubectl apply -f -
	@kubectl apply -f bootstrap/welcome-app/manifests.yaml
	@echo "Waiting for welcome-app rollout..."
	@kubectl rollout status deployment welcome-app -n welcome-app --timeout=60s
	@echo "Welcome app is live at https://links.test"

clean-welcome: ## Delete the temporary welcome app and its namespace
	@kubectl delete -f bootstrap/welcome-app/manifests.yaml --ignore-not-found=true

install-argocd: ## Install ArgoCD with Ingress and wait for rollout
	@kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	@./bootstrap/setup-certs.sh
	@kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.13.3/manifests/install.yaml
	@kubectl patch deployment argocd-server -n argocd --type=json -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--insecure"}]' || true
	@echo "Waiting for argocd-server rollout..."
	@kubectl rollout status deployment argocd-server -n argocd --timeout=300s
	@echo ""
	@echo "ArgoCD is available at https://argo.links.test"
	@echo "Run 'make argocd-pass' to retrieve the initial admin password."

argocd-pass: ## Retrieve the initial admin password for ArgoCD
	@echo -n "Username: admin\nPassword: "
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "Password secret not found (may have been deleted or changed)"
	@echo ""

apply-root-app: ## Apply the ArgoCD root App of Apps manifest from home-lab-gitops repo
	@kubectl apply -f https://raw.githubusercontent.com/vmalani27/home-lab-gitops/main/root-application.yaml || kubectl apply -f ../home-lab-gitops/root-application.yaml
	@echo "Root Application applied. ArgoCD is now tracking home-lab-gitops."

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
