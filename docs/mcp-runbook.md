# MCP Runbook

This runbook documents the operational workflow for the MCP + Foundry investigation path of the Nile K8s Stack project.

## Architecture

```text
Microsoft Foundry Agent
      ↓
localhost.run HTTPS tunnel
      ↓
Kubernetes MCP Server
      ↓
Read-only ServiceAccount
      ↓
Minikube Kubernetes API
```

## 1. Apply RBAC

```bash
kubectl apply -f kubernetes/mcp-rbac.yaml
```

Verify the read-only service account has the expected permissions:

```bash
kubectl auth can-i get pods \
  --as=system:serviceaccount:mcp-system:mcp-k8s-reader \
  -n juice-shop

kubectl auth can-i get pods \
  --as=system:serviceaccount:mcp-system:mcp-k8s-reader \
  -n falco

kubectl auth can-i get pods \
  --as=system:serviceaccount:mcp-system:mcp-k8s-reader \
  -n observability
```

Expected authorization behavior:

```bash
kubectl auth can-i get pods \
  --as=system:serviceaccount:mcp-system:mcp-k8s-reader \
  -n falco
```

This should return `yes`.

A write operation should return `no`, for example:

```bash
kubectl auth can-i delete pods \
  --as=system:serviceaccount:mcp-system:mcp-k8s-reader \
  -n falco
```

## 2. Start the MCP Server

The repository provides the startup script:

```bash
chmod +x scripts/start-mcp.sh
./scripts/start-mcp.sh
```

The script:

1. Verifies required tools.
2. Checks that Minikube is running.
3. Obtains the Kubernetes API endpoint.
4. Extracts the Minikube CA certificate.
5. Creates a short-lived ServiceAccount token.
6. Builds a restricted kubeconfig.
7. Verifies read-only access.
8. Starts the Kubernetes MCP server via SSE on port `8080`.

MCP should be available locally:

```text
http://127.0.0.1:8080
```

## 3. Start the HTTPS Tunnel

In a second terminal:

```bash
chmod +x scripts/start-tunnel.sh
./scripts/start-tunnel.sh
```

This creates a temporary reverse tunnel using `localhost.run`.

The generated public endpoint is then used in Foundry by pointing the MCP connection to:

```text
https://<generated-host>/sse
```

> The tunnel hostname can change when the process is restarted.

## 4. Foundry Workflow

Once the MCP endpoint is configured, the Foundry Agent can query the cluster through the `mcp-k8s-reader` ServiceAccount without using cluster-admin credentials.

Example prompts:

```text
What pods are currently unhealthy?
Investigate recent failures in the juice-shop namespace.
Check whether there are recent Falco runtime alerts.
Look at the Juice Shop deployment and its recent pod events.
```

## 5. Troubleshooting

### MCP endpoint returns 404
Make sure the Foundry MCP URL includes `/sse` and not just the tunnel host.

### MCP endpoint returns 503
Verify both scripts are running:

```bash
./scripts/start-mcp.sh
./scripts/start-tunnel.sh
```

The tunnel must point to the MCP server listening on port `8080`.

### MCP cannot connect to Kubernetes
Verify the restricted identity can read namespace resources:

```bash
kubectl get pods -n juice-shop
kubectl auth can-i get pods \
  --as=system:serviceaccount:mcp-system:mcp-k8s-reader \
  -n juice-shop
```

### Grafana shows no logs
Check the observing namespace and Alloy logs:

```bash
kubectl get pods -n observability
kubectl logs -n observability -l app.kubernetes.io/name=alloy
```

## Operational Notes

- This project intentionally uses a temporary public tunnel for local demonstration purposes.
- The MCP workflow is RBAC-bound and designed to enforce read-only investigation access.
- The detailed RBAC and cluster permissions are documented in the repository manifest files and should be updated as the environment evolves.
