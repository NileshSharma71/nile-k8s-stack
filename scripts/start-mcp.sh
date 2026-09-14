#!/usr/bin/env bash
set -euo pipefail

MCP_KUBECONFIG="/tmp/mcp-kubeconfig"
MCP_CA="/tmp/minikube-ca.crt"
MCP_IMAGE="ghcr.io/feiskyer/mcp-kubernetes-server:latest"
MCP_PORT="${MCP_PORT:-8080}"

echo "==> Checking prerequisites..."

command -v kubectl >/dev/null || {
  echo "ERROR: kubectl not found."
  exit 1
}

command -v minikube >/dev/null || {
  echo "ERROR: minikube not found."
  exit 1
}

command -v docker >/dev/null || {
  echo "ERROR: docker not found."
  exit 1
}

if ! minikube status >/dev/null 2>&1; then
  echo "ERROR: Minikube is not running."
  echo "Run: minikube start"
  exit 1
fi

echo "==> Getting current Kubernetes API server..."

SERVER="$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')"

if [[ -z "$SERVER" ]]; then
  echo "ERROR: Could not determine Kubernetes API server."
  exit 1
fi

echo "    API server: $SERVER"

echo "==> Exporting Minikube CA certificate..."

minikube ssh -- sudo cat /var/lib/minikube/certs/ca.crt > "$MCP_CA"
chmod 600 "$MCP_CA"

if [[ ! -s "$MCP_CA" ]]; then
  echo "ERROR: Failed to create $MCP_CA"
  exit 1
fi

echo "==> Creating fresh read-only ServiceAccount token..."

TOKEN="$(kubectl create token mcp-k8s-reader -n mcp-system)"

if [[ -z "$TOKEN" ]]; then
  echo "ERROR: Failed to create ServiceAccount token."
  exit 1
fi

echo "==> Building restricted kubeconfig..."

cat > "$MCP_KUBECONFIG" <<EOF
apiVersion: v1
kind: Config
clusters:
- name: minikube
  cluster:
    server: ${SERVER}
    certificate-authority: ${MCP_CA}

contexts:
- name: mcp-reader
  context:
    cluster: minikube
    namespace: juice-shop
    user: mcp-k8s-reader

current-context: mcp-reader

users:
- name: mcp-k8s-reader
  user:
    token: ${TOKEN}
EOF

chmod 600 "$MCP_KUBECONFIG"

echo "==> Verifying Kubernetes access..."

KUBECONFIG="$MCP_KUBECONFIG" kubectl get pods -n juice-shop

echo
echo "=============================================="
echo " MCP Kubernetes Server"
echo "=============================================="
echo " Endpoint: http://localhost:${MCP_PORT}/sse"
echo " Kubeconfig: $MCP_KUBECONFIG"
echo
echo " Starting MCP server..."
echo " Keep this terminal open."
echo "=============================================="
echo

exec docker run -i --rm \
  --network host \
  --mount type=bind,src="$MCP_KUBECONFIG",dst=/home/mcp/.kube/config,readonly \
  --mount type=bind,src="$MCP_CA",dst="$MCP_CA",readonly \
  "$MCP_IMAGE" \
  --transport sse \
  --host 0.0.0.0 \
  --port "$MCP_PORT"