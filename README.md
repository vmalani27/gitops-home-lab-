# My Home Lab Setup

Local Multi-Service Engineering Lab using GitOps (ArgoCD "App of Apps") on Minikube (WSL2 Ubuntu).

## Repository Structure

```text
.
├── Makefile                           # Deterministic cluster bootstrap & teardown
├── bootstrap/                         # Host & cluster initialization scripts
│   ├── install-prereqs.sh             # Installs docker, minikube, kubectl, helm, mkcert
│   ├── start-minikube.sh              # Starts minikube with memory/CPU limits & ingress addon
│   ├── setup-certs.sh                 # Generates wildcard *.links.test certs via mkcert
│   └── wslconfig.example              # Host resource limits template
└── gitops/
    ├── root-application.yaml          # ArgoCD Root "App of Apps" manifest
    └── components/                    # Self-contained components (each in its own namespace)
        ├── ingress-nginx/             # Ingress Controller (namespace: ingress-nginx)
        ├── argocd/                    # GitOps Engine & self-config (namespace: argocd)
        ├── postgresql/                # PostgreSQL Database StatefulSet (namespace: postgresql)
        └── url-shortener/             # URL Shortener Microservice (namespace: url-shortener)
            └── chart/                 # Dedicated Helm Chart
```

## Branching Strategy: Feature Flow

* `main`: Represents the active local lab environment. Only thoroughly tested and working components are merged here.
* `feature/<feature-name>`: Atomic feature branches. Used for development, testing, and spinning up ephemeral/mirror test environments before merging.
