#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err()  { echo -e "${RED}[ERROR]${NC} $1"; }

if ! command -v kubectl &>/dev/null; then
    log_err "'kubectl' CLI is not installed or not in your PATH."
    echo -e "Run ${CYAN}make install-tools${NC} to install kubectl, helm, and mkcert."
    exit 1
fi

log_info "Checking Kubernetes cluster connectivity..."
if ! kubectl cluster-info &>/dev/null; then
    log_err "Cannot connect to any Kubernetes cluster with current kubectl context."
    echo ""
    echo -e "${YELLOW}=================================================================${NC}"
    echo -e "${CYAN}How to provide or connect a cluster:${NC}"
    echo ""
    echo "1. If you are learning/running k0s:"
    echo "   - Verify k0s service: sudo k0s status"
    echo "   - Export kubeconfig:  mkdir -p ~/.kube && sudo k0s kubeconfig admin > ~/.kube/config && chmod 600 ~/.kube/config"
    echo ""
    echo "2. If you are learning/running k3s:"
    echo "   - Verify k3s service: sudo systemctl status k3s"
    echo "   - Export kubeconfig:  mkdir -p ~/.kube && sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && sudo chown \$USER:\$USER ~/.kube/config"
    echo ""
    echo "3. If you want to use the automated Minikube sandbox:"
    echo "   - Run: make minikube-start"
    echo "   - Or:  make bootstrap-minikube"
    echo -e "${YELLOW}=================================================================${NC}"
    exit 1
fi

CURRENT_CTX=$(kubectl config current-context 2>/dev/null || echo "unknown")
log_info "Connected to cluster context: ${CYAN}${CURRENT_CTX}${NC}"
echo ""
kubectl get nodes -o wide || true
echo ""
log_info "Cluster is reachable and ready for bootstrap!"
