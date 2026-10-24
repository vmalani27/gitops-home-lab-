#!/usr/bin/env bash
set -euo pipefail

# Colors for log output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err()  { echo -e "${RED}[ERROR]${NC} $1"; }

# 1. Update and install basic dependencies
log_info "Updating package lists and installing base tools..."
sudo apt-get update -y
sudo apt-get install -y curl wget apt-transport-https ca-certificates gnupg lsb-release libnss3-tools make

# 2. Docker verification / installation
if command -v docker &>/dev/null; then
    log_info "Docker is already installed: $(docker --version)"
else
    log_info "Installing Docker Engine..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

# Ensure user is in docker group
if ! groups "$USER" | grep -q '\bdocker\b'; then
    log_info "Adding $USER to docker group..."
    sudo usermod -aG docker "$USER"
    log_warn "User added to docker group. You may need to run 'newgrp docker' or re-login to apply group changes."
fi

# 3. Kubectl
if command -v kubectl &>/dev/null; then
    log_info "Kubectl is already installed: $(kubectl version --client -o yaml | grep gitVersion || true)"
else
    log_info "Installing kubectl from official Kubernetes apt repository..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update -y
    sudo apt-get install -y kubectl
    log_info "kubectl installed: $(kubectl version --client --output=yaml | grep gitVersion || true)"
fi

# 4. Minikube
if command -v minikube &>/dev/null; then
    log_info "Minikube is already installed: $(minikube version --short)"
else
    log_info "Installing Minikube..."
    curl -fsSL --retry 3 --retry-delay 2 -o minikube-linux-amd64 https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm -f minikube-linux-amd64
    log_info "Minikube installed: $(minikube version --short)"
fi

# 5. Helm
if command -v helm &>/dev/null; then
    log_info "Helm is already installed: $(helm version --short)"
else
    log_info "Installing Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    log_info "Helm installed: $(helm version --short)"
fi

# 6. mkcert
if command -v mkcert &>/dev/null; then
    log_info "mkcert is already installed: $(mkcert -version)"
else
    log_info "Installing mkcert..."
    MKCERT_VERSION="v1.4.4"
    curl -fsSL --retry 3 --retry-delay 2 -Lo mkcert "https://github.com/FiloSottile/mkcert/releases/download/${MKCERT_VERSION}/mkcert-${MKCERT_VERSION}-linux-amd64"
    sudo install -m 0755 mkcert /usr/local/bin/mkcert
    rm -f mkcert
    log_info "mkcert installed: $(mkcert -version)"
fi

log_info "All prerequisites are satisfied!"
