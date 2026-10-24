#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

CERT_DIR="$(mktemp -d -t mkcert-certs-XXXXXX)"
trap 'rm -rf "${CERT_DIR}"' EXIT

log_info "Ensuring local CA is installed via mkcert..."
mkcert -install

log_info "Generating wildcard certificate for *.links.test and links.test..."
mkcert -cert-file "${CERT_DIR}/tls.crt" -key-file "${CERT_DIR}/tls.key" "*.links.test" "links.test" "api.links.test" "argo.links.test"

# Namespaces receiving initial certificates
NAMESPACES_WITH_CERTS=("cert-manager" "welcome-app")

for ns in "${NAMESPACES_WITH_CERTS[@]}"; do
    log_info "Ensuring namespace '${ns}' exists..."
    kubectl create namespace "${ns}" --dry-run=client -o yaml | kubectl apply -f -

    log_info "Applying TLS secret 'wildcard-links-test-tls' to namespace '${ns}'..."
    kubectl create secret tls wildcard-links-test-tls \
      --cert="${CERT_DIR}/tls.crt" \
      --key="${CERT_DIR}/tls.key" \
      --namespace="${ns}" \
      --dry-run=client -o yaml | kubectl apply -f -
done

log_info "Wildcard TLS certificates successfully provisioned into: ${NAMESPACES_WITH_CERTS[*]}."
