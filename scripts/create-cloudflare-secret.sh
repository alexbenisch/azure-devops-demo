#!/usr/bin/env bash
# scripts/create-cloudflare-secret.sh
#
# Erzeugt das Secret `cloudflare-api-token` im Namespace cert-manager, das der
# DNS-01 ClusterIssuer nutzt. Der Token wird zur Laufzeit aus einer .env gelesen
# und NIE im Repo gespeichert.
#
# Quelle (überschreibbar per Env):
#   CF_ENV_FILE  = ~/repos/homelab-demo/.env
#   CF_ENV_KEY   = CLOUDFLARE_KUBETEST_API_TOKEN
set -euo pipefail

CF_ENV_FILE="${CF_ENV_FILE:-$HOME/repos/homelab-demo/.env}"
CF_ENV_KEY="${CF_ENV_KEY:-CLOUDFLARE_KUBETEST_API_TOKEN}"

if [[ ! -f "$CF_ENV_FILE" ]]; then
  echo "✗ .env nicht gefunden: $CF_ENV_FILE" >&2
  exit 1
fi

# Wert zur Zeile "KEY=..." extrahieren, optionale Quotes entfernen.
TOKEN="$(grep -E "^${CF_ENV_KEY}=" "$CF_ENV_FILE" | head -n1 | cut -d= -f2- | tr -d '"'"'"'')"
if [[ -z "$TOKEN" ]]; then
  echo "✗ $CF_ENV_KEY nicht in $CF_ENV_FILE gefunden" >&2
  exit 1
fi

kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
kubectl -n cert-manager create secret generic cloudflare-api-token \
  --from-literal=api-token="$TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✓ Secret cloudflare-api-token in Namespace cert-manager angelegt/aktualisiert."
