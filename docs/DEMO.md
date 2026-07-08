---
title: "Azure DevOps Platform Demo — Live-Walkthrough (15 Min)"
author: "Alex Benisch"
date: 2026-07-08
geometry: "margin=1.5cm"
papersize: a4
---

# Live-Walkthrough (15 Min)

> **Pitch (30 s):** „Ein `git push` provisioniert per Terraform die Azure-Basis,
> baut & scannt das Container-Image, pusht es in die ACR und aktualisiert das
> GitOps-Repo. Flux zieht den Change automatisch in den AKS-Cluster. RBAC und
> Policies sind deklarativ, Monitoring läuft ab Minute eins. Rollback = `git revert`."

Diese Demo wurde real deployt (Subscription `mercury`, `westeurope`,
Kubernetes `v1.35.5`) und wieder abgebaut. Die aufgenommenen Nachweise liegen in
[`monitoring.md`](monitoring.md) inkl. Grafana-Screenshots.

---

## 0. Anforderungs-Mapping (30 s Einstieg)

| Anforderung | Umsetzung | Artefakt |
|-------------|-----------|----------|
| Azure IaC | Terraform-Module: RG, VNet, AKS, ACR, Key Vault, Log Analytics | `infra/` |
| RBAC | Azure Custom Role **+** Kubernetes RBAC (AAD-Gruppen) | `infra/modules/rbac/`, `gitops/infrastructure/configs/app-team-role.yaml` |
| Terraform | Modular, Remote State (azurerm), `tfsec` im CI | `infra/`, `.github/workflows/terraform.yml` |
| CI/CD | GitHub Actions **+** Azure DevOps | `.github/workflows/`, `azure-pipelines.yml` |
| Container-Orchestrierung | AKS + Flux CD, HPA, Health Probes, Rollout | `gitops/`, `apps/` |
| Monitoring | Container Insights + kube-prometheus-stack + Alerts | `observability/`, `docs/monitoring.md` |

---

## 1. Terraform — Azure-Basis (3 Min)

**Zeigen:** `infra/` — modularer Aufbau, Remote State, parametrisiert.

```bash
tree infra -L 2
sed -n '1,25p' infra/backend.tf         # Remote State im azurerm-Backend
terraform -chdir=infra plan -var-file=environments/dev.tfvars
```

**Talking Points**
- **Trennung der Verantwortung:** Terraform = alles *unterhalb* des Clusters
  (Azure-Ressourcen, Identitäten, Netz). Flux = alles *innerhalb*.
- **Kein statisches Secret im Cluster:** AKS mit `oidc_issuer_enabled` +
  `workload_identity_enabled`; ACR-Pull über die Kubelet-Managed-Identity
  (`AcrPull`-Role-Assignment), keine `imagePullSecrets`.
- **Real-World-Anpassung (ehrlicher Talking Point):** Das Referenz-Design zielt
  auf D-Serie/`Standard_D2s_v5`. Die Demo-Subscription hatte 10 vCPU Regional-
  Quota und DSv5 = 0. Ich habe VM-Größe & Node-Counts **parametrisiert**
  (`aks_vm_size`, `aks_*_node_*`) und in `dev.tfvars` auf `Standard_D2s_v3`
  gesetzt — Design bleibt, Deploy passt ins Kontingent. → zeigt Adaptierbarkeit.

---

## 2. RBAC auf zwei Ebenen (3 Min)

**Zeigen:** beide Ebenen — viele Kandidaten bleiben hier oberflächlich.

```bash
sed -n '1,40p' infra/modules/rbac/main.tf                       # Azure Custom Role (Least Privilege)
cat gitops/infrastructure/configs/app-team-role.yaml            # K8s Role/RoleBinding
```

**Talking Points**
- **Azure RBAC** steuert *wer darf auf Cluster/Ressourcen zugreifen*; die Custom
  Role „AKS Deployer" darf lesen & Credentials ziehen, aber **nicht** löschen
  (`not_actions`).
- **Kubernetes RBAC** steuert *was darf man im Cluster tun* — Namespace-scoped,
  gebunden an eine **AAD-Gruppe (objectId)**, nie an Einzelnutzer.
- `azure_rbac_enabled = true` + `local_account_disabled = true` ⇒ Zugriff nur
  über Azure AD. **Live-Beleg:** Selbst als Owner brauchte ich ein explizites
  Role-Assignment (*AKS RBAC Cluster Admin*) + `kubelogin`, um `kubectl` zu nutzen.

---

## 3. CI/CD (3 Min)

**Zeigen:** GitHub Actions (Terraform-Plan/Apply + Build/Scan/Push) und das
Azure-DevOps-Äquivalent.

```bash
sed -n '1,40p' .github/workflows/terraform.yml        # OIDC-Login, tfsec, plan/apply
sed -n '1,60p' .github/workflows/build-and-push.yml   # Test -> Build -> Trivy -> GitOps-Bump
```

**Talking Points**
- **OIDC statt Client-Secret** (`id-token: write`) — keine langlebigen Azure-
  Credentials im Repo.
- **CI = bauen/testen/scannen** (pytest, `tfsec`, Trivy-Image-Scan mit
  `exit-code: 1`). **CD = GitOps-Pull** — die Pipeline macht *kein* `kubectl
  apply`, sondern committet den neuen Image-Tag; Flux deployt.
- Beides vorhanden ⇒ Antwort auf „GitHub Actions oder Azure DevOps?": „Kann ich
  beides, gleiche Prinzipien."

---

## 4. GitOps mit Flux — der Kern (3 Min)

**Zeigen:** die **geschichtete** Reconciliation und den Live-Sync.

```bash
tree gitops -L 3
flux get kustomizations          # infra-controllers -> infra-configs -> apps
flux get helmreleases -A
kubectl get pods -n app -o wide
```

**Talking Points**
- **Layering (wichtigster technischer Punkt):** `controllers → configs → apps`
  mit `dependsOn` + `wait: true`. Grund: CRs (`ClusterIssuer`, kyverno
  `ClusterPolicy`) brauchen ihre CRDs *vorher*. Ein flacher Apply scheitert am
  Dry-Run — die Schichtung löst das deterministisch. (Das ist genau der Fehler,
  den ich beim ersten Bootstrap live gesehen und behoben habe.)
- **Rollback = `git revert`** — kein imperativer Eingriff.
- **Namespace-Ownership:** der `app`-Namespace wird **genau einmal** (in
  `configs`) verwaltet, damit sich Kustomizations nicht darum streiten.

---

## 5. Policy-as-Code — Kyverno (1–2 Min)

**Zeigen:** Enforcement live beweisen.

```bash
kubectl get cpol                                     # Enforce / Ready
# PSS-konformer Pod, aber falsche Registry -> von Kyverno abgelehnt:
kubectl run rogue --image=docker.io/library/busybox -n app --overrides='{"spec":{"securityContext":{"runAsNonRoot":true,"runAsUser":10001,"seccompProfile":{"type":"RuntimeDefault"}},"containers":[{"name":"c","image":"docker.io/library/busybox","securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}}]}}'
```

→ *„…blocked: allowed-image-registries: Images müssen aus …azurecr.io stammen."*

**Talking Points**
- Zwei Verteidigungslinien: **Pod Security Admission** (`restricted` am Namespace)
  *und* **Kyverno** (non-root erzwingen, nur ACR-Images). Defense in Depth.

---

## 6. Monitoring (2 Min)

**Zeigen:** `docs/monitoring.md` mit den Live-Grafana-Screenshots.

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
#  Grafana -> Compute Resources / Cluster, Node Exporter, API server SLO
```

**Talking Points**
- **Zweigleisig:** Azure Container Insights (out-of-cluster, ausfallsicher) +
  kube-prometheus-stack (in-cluster, 25 gesunde Scrape-Targets, 148 Alert-Rules).
- Eigene Alerts (`PodCrashLooping`, `HighPodCpu`, `DeploymentReplicasMismatch`)
  verlinken je auf ein **Runbook** unter `observability/runbooks/`.
- **Fehlerbehebung:** `events → describe → logs --previous → Grafana → Log-
  Analytics-KQL`; kritische Alerts zusätzlich an eine Azure Action Group.

---

## 7. Wenn Zeit bleibt / typische Nachfragen

- **Secret-Management:** Grafana-Default-Passwort → in Prod via Key Vault + CSI
  Secret Store Driver (Key Vault ist bereits provisioniert).
- **Multi-Environment:** `dev`/`prod` über tfvars + Flux-Overlays (Kustomize).
- **Progressive Delivery:** Flagger für Canary auf Basis von Prometheus-Metriken.
- **Drift Detection:** `terraform plan` als geplanter Job + Flux-Reconcile-Alerts.

---

## 8. Reproduzieren & Abbauen

```bash
export GITHUB_USER=<user>
./scripts/bootstrap.sh          # State -> Terraform -> kubeconfig -> CF-Secret -> Flux
flux get kustomizations --watch
./scripts/smoke-test.sh

# Teardown (Kosten stoppen):
terraform -chdir=infra destroy -var-file=environments/dev.tfvars
```

> Der Terraform-State (`rg-tfstate` / Storage Account) wird out-of-band angelegt
> und bewusst **nicht** von Terraform verwaltet (Henne-Ei-Problem).

> **Bekanntes Teardown-Detail:** `terraform destroy` kann am Node-Pool-Drain
> hängen (PodDisruptionBudgets blockieren die Eviction). Workaround + offene
> Terraform-Lösung siehe [`teardown-and-audit.md`](teardown-and-audit.md).
