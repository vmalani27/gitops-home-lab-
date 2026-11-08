#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err()  { echo -e "${RED}[ERROR]${NC} $1"; }

# 1. Check if an ingress controller or ingress class is already installed
if kubectl get ingressclass nginx &>/dev/null || kubectl get deployment -n ingress-nginx ingress-nginx-controller &>/dev/null; then
    log_info "Ingress controller (nginx) is already installed."
    exit 0
fi

log_info "No Ingress controller found. Installing Ingress-NGINX..."

if command -v helm &>/dev/null; then
    log_info "Deploying Ingress-NGINX via Helm..."
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx --force-update >/dev/null 2>&1 || true
    helm repo update >/dev/null 2>&1 || true

    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
      --namespace ingress-nginx \
      --create-namespace \
      --set controller.service.type=NodePort \
      --set controller.hostPort.enabled=true \
      --wait \
      --timeout=180s
else
    log_info "Helm not found; deploying Ingress-NGINX via official baremetal manifest..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0/deploy/static/provider/baremetal/deploy.yaml
    log_info "Waiting for Ingress controller rollout..."
    kubectl rollout status deployment ingress-nginx-controller -n ingress-nginx --timeout=180s
fi

log_info "Ingress-NGINX is successfully installed and ready."
