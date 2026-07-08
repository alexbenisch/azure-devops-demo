#!/usr/bin/env bash
# scripts/bootstrap.sh — End-to-end Setup der Demo-Plattform.
#
# Reihenfolge: TF-State-Backend -> Terraform (Azure-Basis) -> kubeconfig ->
# Cloudflare-Secret -> Flux Bootstrap (GitOps übernimmt den Rest).
set -euo pipefail

: "${GITHUB_USER:?GITHUB_USER muss gesetzt sein}"
REPO="${REPO:-azure-devops-demo}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
LOCATION="${LOCATION:-westeurope}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "▶ 1/5  Terraform-State-Backend sicherstellen (out-of-band)"
az group create -n rg-tfstate -l "$LOCATION" >/dev/null
az storage account create -n sttfstatedemo -g rg-tfstate -l "$LOCATION" \
  --sku Standard_LRS --encryption-services blob >/dev/null
az storage container create -n tfstate --account-name sttfstatedemo >/dev/null
echo "   ✓ Backend bereit"

echo "▶ 2/5  Terraform Apply (Azure-Basis)"
terraform -chdir="$REPO_ROOT/infra" init
terraform -chdir="$REPO_ROOT/infra" apply -auto-approve \
  -var-file="environments/${ENVIRONMENT}.tfvars"

CLUSTER="$(terraform -chdir="$REPO_ROOT/infra" output -raw aks_cluster_name)"
RG="$(terraform -chdir="$REPO_ROOT/infra" output -raw resource_group_name)"

echo "▶ 3/5  kubeconfig ziehen für Cluster $CLUSTER"
az aks get-credentials -g "$RG" -n "$CLUSTER" --overwrite-existing

echo "▶ 4/5  Cloudflare-API-Token-Secret für cert-manager"
"$REPO_ROOT/scripts/create-cloudflare-secret.sh"

echo "▶ 5/5  Flux Bootstrap (GitOps)"
flux bootstrap github \
  --owner="$GITHUB_USER" \
  --repository="$REPO" \
  --branch="main" \
  --path="gitops/clusters/demo" \
  --personal

echo "✓ Bootstrap abgeschlossen. 'flux get kustomizations --watch' zeigt den Sync."
