#!/usr/bin/env bash
set -euo pipefail

LOCAL_PORT="${LOCAL_PORT:-8080}"

command -v ssh >/dev/null || {
  echo "ERROR: ssh not found."
  exit 1
}

if ! nc -z 127.0.0.1 "$LOCAL_PORT" 2>/dev/null; then
  echo "WARNING: Nothing appears to be listening on localhost:${LOCAL_PORT}."
  echo "Start ./scripts/start-mcp.sh first."
  exit 1
fi

echo "==> Starting localhost.run tunnel..."
echo "==> Forwarding public HTTPS -> localhost:${LOCAL_PORT}"
echo
echo "Keep this terminal open."
echo "When localhost.run prints the public URL, use:"
echo "    https://<generated-host>/sse"
echo
echo "=============================================="
echo

exec ssh -R "80:localhost:${LOCAL_PORT}" nokey@localhost.run