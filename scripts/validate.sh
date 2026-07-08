#!/usr/bin/env bash
# scripts/validate.sh — Pre-Commit Qualitäts-Gate.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "▶ Terraform Format & Validate"
terraform -chdir=infra fmt -check -recursive
terraform -chdir=infra init -backend=false >/dev/null
terraform -chdir=infra validate

echo "▶ tfsec (IaC Security Scan)"
tfsec infra/

echo "▶ YAML Lint (Kubernetes-Manifeste)"
find gitops apps observability -name '*.yaml' -print0 | xargs -0 yamllint -d relaxed

echo "▶ Kubeconform (Manifest-Schema-Validierung)"
find apps/sample-api/k8s -name '*.yaml' -exec \
  kubeconform -strict -ignore-missing-schemas {} +

echo "✓ Alle Checks bestanden."
