#!/usr/bin/env bash
# scripts/smoke-test.sh — Post-Deploy Health-Check.
set -euo pipefail
NS="${NS:-app}"

echo "▶ Warte auf Rollout..."
kubectl -n "$NS" rollout status deployment/sample-api --timeout=120s

echo "▶ Health-Endpoint prüfen..."
if kubectl -n "$NS" run curl --rm -i --restart=Never --image=curlimages/curl -- \
     curl -sf http://sample-api/healthz; then
  echo "✓ App gesund"
else
  echo "✗ Health-Check fehlgeschlagen"
  exit 1
fi
