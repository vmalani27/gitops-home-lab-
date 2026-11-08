SHELL := /bin/bash
.PHONY: help check-cluster install-ingress certs welcome clean-welcome bootstrap install-argocd argocd-pass sync-kubeconfig status ingress-forward tunnel install-tools minikube-prereqs minikube-start minikube-stop minikube-clean bootstrap-minikube prereqs start stop clean

help: ## Show this help message
	@echo "================================================================="
	@echo " Local Kubernetes & GitOps Platform Lab"
	@echo "================================================================="
	@echo ""
	@echo "TRACK 1: Any Kubernetes Cluster (Manual k0s, k3s, Kind, Bare-Metal)"
	@echo "  make check-cluster       Verify connection to current active Kubernetes cluster"
	@echo "  make install-ingress     Install Ingress-NGINX if missing"
	@echo "  make certs               Generate local wildcard TLS certs (*.links.test)"
	@echo "  make welcome             Deploy onboarding test app to https://links.test"
	@echo "  make bootstrap           Bootstrap active cluster (verify, certs, welcome, sync)"
	@echo "  make install-argocd      Install ArgoCD with Ingress and wait for rollout"
	@echo "  make sync-kubeconfig     Sync WSL2 kubeconfig to Windows host profile"
	@echo "  make install-tools       Install client CLI tools only (kubectl, helm, mkcert)"
	@echo ""
	@echo "TRACK 2: Learn with Minikube Sandbox (Automated zero-to-cluster)"
	@echo "  make minikube-prereqs    Install Docker, Minikube, and client CLIs"
	@echo "  make minikube-start      Start tuned Minikube with Ingress addon"
	@echo "  make minikube-stop       Stop Minikube cluster"
	@echo "  make minikube-clean      Delete Minikube cluster"
	@echo "  make bootstrap-minikube  Start Minikube + full bootstrap in one shot"
	@echo ""
	@echo "GENERAL HELPERS:"
	@echo "  make status              Show active cluster info, nodes, and pods"
	@echo "  make ingress-forward     Forward ingress controller to localhost:80 & 443"
	@echo "  make tunnel              Start minikube tunnel (if using Minikube)"
	@echo "  make argocd-pass         Print initial admin password for ArgoCD"
	@echo "================================================================="

# =================================================================
# TRACK 1: CLUSTER-AGNOSTIC BOOTSTRAP (k0s, k3s, or any Kubernetes)
# =================================================================

check-cluster: ## Check connectivity to current active Kubernetes cluster
	@chmod +x bootstrap/*.sh
	@./bootstrap/check-cluster.sh

install-ingress: ## Install Ingress-NGINX if no ingress controller is detected
	@chmod +x bootstrap/*.sh
	@./bootstrap/install-ingress.sh

certs: ## Generate wildcard certificates (*.links.test) and inject into Kubernetes secrets
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

bootstrap: check-cluster install-ingress certs welcome sync-kubeconfig ## Bootstrap whatever cluster kubectl points to (no prereqs/minikube required)
	@echo ""
	@echo "================================================================="
	@echo "Cluster baseline bootstrap complete!"
	@echo "Add the following line to your hosts file if not already present:"
	@echo "127.0.0.1  links.test argo.links.test demo.links.test"
	@echo ""
	@echo "If your cluster needs traffic forwarded to host localhost:80/443:"
	@echo "  make ingress-forward"
	@echo ""
	@echo "Welcome app is live at: https://links.test"
	@echo ""
	@echo "Next step: Install ArgoCD engine:"
	@echo "  make install-argocd"
	@echo "================================================================="

install-argocd: ## Install ArgoCD with Ingress and wait for rollout
	@kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	@./bootstrap/setup-certs.sh
	@kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.13.3/manifests/install.yaml
	@kubectl patch deployment argocd-server -n argocd --type=json -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--insecure"}]' || true
	@kubectl apply -f bootstrap/argocd-ingress.yaml
	@echo "Waiting for argocd-server rollout..."
	@kubectl rollout status deployment argocd-server -n argocd --timeout=300s
	@echo ""
	@echo "================================================================="
	@echo "Basic platform bootstrapping is complete!"
	@echo "ArgoCD is available at https://argo.links.test"
	@echo "Run 'make argocd-pass' to retrieve the initial admin password."
	@echo ""
	@echo "NEXT STEP (GitOps Hand-off):"
	@echo "  1. Clone your GitOps applications repository:"
	@echo "     git clone https://github.com/vmalani27/gitops-repo-apps.git"
	@echo "  2. Apply the root application manifest from that repository:"
	@echo "     cd gitops-repo-apps"
	@echo "     kubectl apply -f root-application.yaml"
	@echo "  3. ArgoCD will sync and deploy your applications (e.g., demo-app)."
	@echo "================================================================="

argocd-pass: ## Retrieve the initial admin password for ArgoCD
	@PASS=$$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d); \
	if [ -n "$$PASS" ]; then \
		echo ""; \
		echo "================================================================="; \
		echo "                     ArgoCD Credentials                          "; \
		echo "================================================================="; \
		echo "  URL:      https://argo.links.test"; \
		echo "  Username: admin"; \
		printf "  Password: %s\n" "$$PASS"; \
		echo "================================================================="; \
		echo ""; \
	else \
		echo ""; \
		echo "================================================================="; \
		echo " [!] Initial admin secret not found."; \
		echo "     It may have been deleted or the password was changed."; \
		echo "================================================================="; \
		echo ""; \
	fi

install-tools: ## Install client CLI tools only (kubectl, helm, mkcert) without Docker or Minikube
	@chmod +x bootstrap/*.sh
	@./bootstrap/install-prereqs.sh --tools-only

# =================================================================
# TRACK 2: MINIKUBE SANDBOX (Automated learning cluster)
# =================================================================

minikube-prereqs: ## Install tools inside Ubuntu WSL2 (docker, minikube, kubectl, helm, mkcert)
	@chmod +x bootstrap/*.sh
	@./bootstrap/install-prereqs.sh

minikube-start: ## Start Minikube cluster with tuned specs and ingress addon
	@chmod +x bootstrap/*.sh
	@./bootstrap/start-minikube.sh

minikube-stop: ## Stop Minikube cluster
	@minikube stop

minikube-clean: ## Destroy Minikube cluster
	@minikube delete

bootstrap-minikube: minikube-prereqs minikube-start bootstrap ## Full automated sandbox: install tools, boot Minikube, and bootstrap

# Aliases for backward compatibility
prereqs: minikube-prereqs
start: minikube-start
stop: minikube-stop
clean: minikube-clean

# =================================================================
# GENERAL HELPERS
# =================================================================

tunnel: ## Start minikube tunnel (requires sudo; binds ingress/loadbalancers to localhost)
	@minikube tunnel

ingress-forward: ## Forward ingress controller to localhost (80 & 443) for host access
	@echo "Forwarding Ingress Controller to localhost:80 and localhost:443..."
	@sudo KUBECONFIG=$$HOME/.kube/config kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 80:80 443:443 --address 0.0.0.0

status: ## Show cluster context, nodes, and pods
	@kubectl config current-context 2>/dev/null && echo "" || true
	@kubectl get nodes -o wide || true
	@echo ""
	@kubectl get pods -A || true

sync-kubeconfig: ## Export flattened kubeconfig from WSL2 to Windows host (%USERPROFILE%\.kube\config)
	@mkdir -p /mnt/c/Users/$$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')/.kube
	@kubectl config view --minify --flatten > /mnt/c/Users/$$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')/.kube/config
	@echo "Kubeconfig successfully synced to Windows host (%USERPROFILE%\.kube\config)"
