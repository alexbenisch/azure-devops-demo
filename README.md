# Azure DevOps Platform Demo

Produktionsnahe Azure-Plattform als *Everything-as-Code*: Terraform provisioniert die
Azure-Basis, Flux (GitOps) verwaltet den Cluster-State, CI/CD baut & scannt, Monitoring
läuft von Minute eins.

> Die ausführliche Konzept-/Präsentationsvorlage liegt in `azure-devops-demo-konzept.md`
> (lokal, nicht eingecheckt).

## Anforderungs-Mapping

| Anforderung | Umsetzung | Ort |
|-------------|-----------|-----|
| Azure IaC | Terraform-Module (RG, VNet, AKS, ACR, Key Vault, Log Analytics) | `infra/` |
| RBAC | Azure Custom Role **und** Kubernetes RBAC | `infra/modules/rbac/`, `gitops/rbac/` |
| Terraform | Modular, Remote State, `tfsec` im CI | `infra/`, `.github/workflows/terraform.yml` |
| CI/CD | GitHub Actions **und** Azure DevOps | `.github/workflows/`, `azure-pipelines.yml` |
| Container-Orchestrierung | AKS + Flux CD, HPA, Health Probes, Rollout | `gitops/`, `apps/` |
| Monitoring | Container Insights + kube-prometheus-stack + Alerts | `observability/`, `gitops/infrastructure/monitoring/` |

## Struktur

```
infra/            Terraform — Azure-Basis (Module: network, aks, acr, keyvault, monitoring, rbac)
gitops/           Flux CD — Cluster-State (infrastructure + apps Kustomizations, RBAC)
apps/sample-api/  FastAPI-Demo-App (src, tests, Dockerfile, k8s-Manifeste)
observability/    Alert-Rules, Grafana-Dashboards, Runbooks
scripts/          bootstrap / validate / smoke-test
.github/workflows CI/CD (GitHub Actions)
azure-pipelines.yml  CI/CD (Azure DevOps Alternative)
```

## Quickstart

```bash
# Voraussetzungen: az, terraform, kubectl, flux, docker
export GITHUB_USER=<dein-github-user>
export REPO=azure-devops-demo

./scripts/bootstrap.sh        # State-Backend -> Terraform -> kubeconfig -> CF-Secret -> Flux
flux get kustomizations --watch
./scripts/smoke-test.sh
```

Nur Validierung (ohne Azure):

```bash
./scripts/validate.sh         # terraform fmt/validate, tfsec, yamllint, kubeconform
```

## DNS / TLS

cert-manager nutzt einen **Cloudflare DNS-01** ClusterIssuer
(`gitops/infrastructure/cert-manager/cluster-issuer.yaml`). Der API-Token wird zur
Laufzeit aus einer lokalen `.env` in ein Kubernetes-Secret geschrieben — nie im Repo:

```bash
./scripts/create-cloudflare-secret.sh   # liest CLOUDFLARE_KUBETEST_API_TOKEN aus ~/repos/homelab-demo/.env
```

## Trennung der Verantwortlichkeiten

- **Terraform** = alles *unterhalb* des Clusters (Azure-Ressourcen, Identitäten, Netzwerk).
- **Flux/GitOps** = alles *innerhalb* des Clusters (Deployments, Policies, Ingress).
- **CI** = bauen, testen, scannen. **CD** = GitOps-Pull (kein `kubectl apply` aus der Pipeline).
- **Rollback** = `git revert`.
