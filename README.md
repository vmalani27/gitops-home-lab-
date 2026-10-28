# Local DevOps Engineering Lab

A self-contained, reproducible Kubernetes engineering environment running locally on Minikube with Ingress-NGINX and trusted local wildcard TLS. Built to model production GitOps workflows without needing cloud spend.

---

## Prerequisites

Before starting, ensure you have the following installed on your machine:

1. **Linux Environment**:
   * Windows 11 with **WSL2 (Ubuntu 22.04 LTS)**, or a native Linux distribution (Ubuntu/Debian).
2. **Hardware Constraints (Recommended for 16 GB RAM hosts)**:
   * Copy `bootstrap/wslconfig.example` to `%USERPROFILE%\.wslconfig` on Windows to cap WSL2 at 6 GB RAM and 4 vCPUs.
3. **Core Host Tools**:
   * Git and `make` (the bootstrap script handles the rest: Docker, Minikube, Kubectl, Helm, and `mkcert`).

---

## Quickstart (One Command Bootstrap)

### 1. Clone the repository
```bash
git clone https://github.com/vmalani27/gitops-home-lab-.git
cd gitops-home-lab-
```

### 2. Run the bootstrap target
From your Linux / WSL2 terminal, run:
```bash
make bootstrap
```
This single command:
1. Installs missing prerequisites (`docker`, `minikube`, `kubectl`, `helm`, `mkcert`).
2. Starts Minikube with tuned resource caps (3 vCPUs, 4096 MB RAM, Docker driver) and enables the `ingress` and `storage-provisioner` addons.
3. Generates trusted local wildcard certificates via `mkcert`, injects them into Kubernetes (`cert-manager`, `welcome-app`), and automatically imports the public CA (`rootCA.pem`) into the Windows Host Root Certificate Store via `certutil.exe`.
4. Deploys the onboarding welcome application.
5. Syncs the cluster `kubeconfig` to your Windows host profile (`%USERPROFILE%\.kube\config`) so tools like VS Code, k9s, and Lens work out of the box.

---

## Local DNS / Hosts File Configuration

To allow your browser to resolve the local cluster ingress, add this line to your hosts file:

* **Windows**: `C:\Windows\System32\drivers\etc\hosts` (open as Administrator)
* **Linux / WSL2**: `/etc/hosts`

```text
127.0.0.1  links.test argo.links.test demo.links.test
```

---

## Accessing the Lab

Because Minikube runs inside a Docker network bridge in WSL2, forward the ingress controller to your host:

```bash
make ingress-forward
```
*(Alternatively, run `minikube tunnel` in a separate terminal).*

Once running, navigate to:
**https://links.test**

You will see the welcome dashboard with a green, trusted HTTPS padlock (signed by your machine's local `mkcert` root CA).

---

## Repository Structure

This repository is dedicated strictly to **cluster lifecycle and bootstrap automation**. All declarative applications, database workloads, and service manifests are managed in the companion GitOps repository: **[`gitops-repo-apps`](https://github.com/vmalani27/gitops-repo-apps)**.

```text
.
├── Makefile                           # Unified cluster lifecycle and bootstrap commands
└── bootstrap/                         # Host & cluster initialization scripts
    ├── install-prereqs.sh             # Idempotent installer for docker, minikube, kubectl, helm, mkcert
    ├── start-minikube.sh              # Boots minikube with memory/CPU limits & ingress addon
    ├── setup-certs.sh                 # Generates wildcard *.links.test certs via mkcert
    ├── wslconfig.example              # Host resource limits template
    └── welcome-app/                   # Onboarding landing page deployed to https://links.test
        ├── html/index.html            # Standalone editorial notebook UI
        └── manifests.yaml             # Deployment, Service, Ingress manifests
```

---

## Common Commands

| Command | Purpose |
|---|---|
| `make bootstrap` | Full end-to-end setup (prereqs, minikube, certs, welcome app). |
| `make install-argocd` | Installs ArgoCD v2.13.3 with Ingress and waits for rollout. |
| `make argocd-pass` | Prints the initial admin password for ArgoCD. |
| `make apply-root-app` | Applies the root "App of Apps" manifest to ArgoCD. |
| `make ingress-forward` | Bridge ingress traffic to `localhost:80` and `localhost:443`. |
| `make status` | Inspect Minikube health, nodes, and running pods. |
| `make sync-kubeconfig` | Re-sync flattened cluster credentials to `%USERPROFILE%\.kube\config`. |
| `make stop` | Gracefully shut down the Minikube cluster. |
| `make clean` | Destroy the Minikube cluster. |

---

## Security & Secrets Policy

* No TLS private keys, certificates, secrets, or `.env` files are committed to this repository.
* All TLS assets are generated locally on-the-fly via `mkcert` and injected directly into cluster memory as Kubernetes secrets.
