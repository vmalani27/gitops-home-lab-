#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

CPUS=${CPUS:-3}
MEMORY=${MEMORY:-4096m}
DRIVER=${DRIVER:-docker}

# Verify Docker daemon is running
if ! docker info &>/dev/null; then
    log_warn "Docker service is not responding. Attempting to start dockerd..."
    sudo service docker start || sudo systemctl start docker || true
    sleep 2
    if ! docker info &>/dev/null; then
        echo -e "${RED}[ERROR]${NC} Docker daemon is not running. Please start Docker service or Docker Desktop."
        exit 1
    fi
fi

# Check Minikube status
if minikube status &>/dev/null; then
    log_info "Minikube is already running."
else
    log_info "Starting Minikube (driver=${DRIVER}, cpus=${CPUS}, memory=${MEMORY})..."
    minikube start \
      --driver="${DRIVER}" \
      --cpus="${CPUS}" \
      --memory="${MEMORY}" \
      --addons=ingress,default-storageclass,storage-provisioner

    log_info "Waiting for Ingress Controller deployment to be ready..."
    kubectl rollout status deployment ingress-nginx-controller -n ingress-nginx --timeout=180s || true
fi

log_info "Minikube is ready. Cluster status:"
minikube status
