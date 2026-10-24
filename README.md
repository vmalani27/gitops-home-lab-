# My Home Lab Setup

Local Multi-Service Engineering Lab using GitOps (ArgoCD "App of Apps") on Minikube (WSL2 Ubuntu).

## Repository Structure

```text
.
├── Makefile                           # Deterministic cluster bootstrap & teardown
├── bootstrap/                         # Host & cluster initialization scripts
│   ├── install-prereqs.sh             # Installs docker, minikube, kubectl, helm, mkcert
│   ├── start-minikube.sh              # Starts minikube with memory/CPU limits & ingress addon
│   └── setup-certs.sh                 # Generates wildcard *.links.test certs via mkcert
├── gitops/
│   ├── root-application.yaml          # ArgoCD Root "App of Apps" manifest
│   ├── infrastructure/                # Platform tooling (Waves 0-1)
│   │   ├── namespaces/                # Wave 0: Namespaces
│   │   ├── ingress-nginx/             # Wave 1: Ingress controller
│   │   ├── certificates/              # Wave 1: Wildcard TLS Secret
│   │   └── argocd/                    # ArgoCD self-configuration
│   └── apps/                          # Databases & applications (Waves 2-3)
│       ├── postgresql/                # Wave 2: PostgreSQL StatefulSet
│       └── url-shortener/             # Wave 3: URL Shortener microservice
│           └── chart/                 # Dedicated Helm Chart
```

## Branching Strategy: Feature Flow

* `main`: Represents the active local lab environment. Only thoroughly tested and working components are merged here.
* `feature/<feature-name>`: Atomic feature branches. Used for development, testing, and spinning up ephemeral/mirror test environments before merging.
