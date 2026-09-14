# Nile K8s Stack

Production-inspired DevSecOps lab built on Kubernetes.

## Overview

Nile K8s Stack is a local Kubernetes security and observability project that combines application deployment, centralized logging, vulnerability scanning, runtime detection, chaos testing, and AI-assisted investigation through an MCP-enabled Kubernetes workflow.

## Architecture

```text
GitHub Actions (Trivy IaC + Image Scan)
      ↓
Minikube Cluster
  ├─ Juice Shop application
  ├─ Alloy → Loki → S3
  ├─ Grafana
  ├─ Falco runtime detection
  ├─ Trivy Operator
  └─ Chaos Mesh resilience testing
      ↓
Foundry Agent → MCP → Restricted Kubernetes ServiceAccount
      ↓
localhost.run HTTPS tunnel
```

## What I Built

- Centralized Kubernetes logging with Alloy, Loki, and Grafana
- Persistent Loki storage backed by Amazon S3
- Shift-left security scanning with Trivy in GitHub Actions
- In-cluster security reporting through Trivy Operator
- Runtime threat detection with Falco
- Resilience testing with Chaos Mesh
- AI-assisted Kubernetes investigation using MCP and Microsoft Foundry
- Tried Least-privilege Kubernetes RBAC for the AI investigation workflow

## Tech Stack

| Area | Technologies |
| --- | --- |
| Orchestration | Kubernetes, Minikube |
| Infrastructure | Terraform |
| Application | OWASP Juice Shop |
| Logging | Grafana Loki, Alloy |
| Visualization | Grafana |
| Storage | Amazon S3 |
| Security | Trivy, Trivy Operator, Falco |
| Resilience | Chaos Mesh |
| AI / Kubernetes | MCP, Microsoft Foundry |
| CI | GitHub Actions |
| Runtime | Docker |

## Project Structure

```text
nile-k8s-stack/
├── kubernetes/
│   ├── juice-shop.yaml
│   ├── alloy-values.yaml
│   ├── grafana-values.yaml
│   ├── loki-values.yaml
│   ├── loki-secrets.yaml
│   ├── mcp-rbac.yaml
│   └── chaos-juice-shop-pod-kill.yaml
├── scripts/
│   ├── start-mcp.sh
│   └── start-tunnel.sh
├── terraform/
│   └── ...
└── docs/
    └── mcp-runbook.md
```

## Quick Start

```bash
minikube start
kubectl apply -f kubernetes/juice-shop.yaml
./scripts/start-mcp.sh
./scripts/start-tunnel.sh
```

The repository also includes Helm and Terraform configuration for the observability and infrastructure layers.

## AI-Assisted Operations

The project uses a restricted Kubernetes ServiceAccount and a read-only RBAC boundary for the MCP server rather than exposing cluster-admin credentials. The workflow starts the MCP server locally and creates an HTTPS endpoint through a public tunnel so the Microsoft Foundry Agent can investigate the cluster through the allowed Kubernetes permissions.

Example prompts:

```text
What pods are currently unhealthy?
Investigate recent failures in the juice-shop namespace.
Check whether there are recent Falco runtime alerts.
```

## Security Model

```text
GitHub Actions → Trivy → IaC + image scanning
Trivy Operator → VulnerabilityReport / ConfigAuditReport / ExposedSecretReport
Falco → Runtime detection → Alloy → Loki → Grafana
```

The AI layer is intentionally constrained to read-only Kubernetes access through the `mcp-k8s-reader` ServiceAccount.

## Limitations

- This is a local learning and portfolio environment, not a production deployment.
- The HTTPS tunnel is temporary and is not an enterprise ingress or authentication layer.
- Juice Shop is intentionally deployed from an upstream image for vulnerability demonstration.
- The implementation runs on Minikube rather than a managed Kubernetes platform.

## Future Improvements

- Replace the localhost tunnel with a stable authenticated ingress.
- Use managed Kubernetes and workload identity.
- Add enterprise SSO and stronger MCP endpoint security.
- Build and sign application images in CI.
- Expand admission policy and secrets management coverage.

For the MCP server startup, tunnel setup, RBAC verification, and troubleshooting flow, see the runbook in [docs/mcp-runbook.md](docs/mcp-runbook.md).
