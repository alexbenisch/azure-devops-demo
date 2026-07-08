---
title: "Teardown-Incident & Audit-Log"
author: "Alex Benisch"
date: 2026-07-08
geometry: "margin=1.5cm"
papersize: a4
---

# Teardown-Incident & Audit-Log

## 1. Was passiert ist

Beim `terraform destroy` blieb der **User-Node-Pool** hängen und ging nach
~30 Min in den Status **`Failed`** (Activity-Log: *„Delete Agent Pool — Failed"*,
`2026-07-08T16:22Z`). Der Cluster selbst blieb `Succeeded`, `terraform` pollte
die fehlgeschlagene Löschung endlos.

**Wahrscheinliche Ursache:** Beim Löschen eines Agent-Pools **cordoned + drained**
AKS die Nodes und respektiert dabei **PodDisruptionBudgets**. Der
`kube-prometheus-stack` (und weitere Charts) bringen PDBs mit, die die Eviction
blockieren → Drain schlägt fehl → Agent-Pool-Delete `Failed`.

## 2. Workaround (CLI) — so wurde abgebaut

```bash
# 1. hängenden terraform-Prozess stoppen
pkill -f "terraform.*destroy"

# 2. Cluster als Ganzes löschen — überspringt den graziösen Node-Drain
az aks delete -g rg-devops-dev -n aks-devops-dev --yes

# 3. Rest sauber über Terraform (Cluster ist nun weg, State bleibt konsistent)
terraform -chdir=infra destroy -auto-approve -var-file=environments/dev.tfvars
#   -> Destroy complete! Resources: 4 destroyed. (vnet, subnet, log analytics, rg)
```

Endzustand: `rg-devops-dev` gelöscht, Terraform-State leer, kein `MC_`-Rest-RG.
Nur `rg-tfstate` (Remote-State-Backend, out-of-band) bleibt bewusst bestehen.

> Hinweis: `az`-Befehle warfen kosmetisch `deadlock detected … serviceconnector`
> (Bug der serviceconnector-Extension) — der eigentliche Befehl lief trotzdem
> durch (Exit 0, Ressource danach `ResourceNotFound`).

## 3. Offene Frage für morgen — wie löst man das *in Terraform*?

Ziel: `terraform destroy` soll in **einem** Lauf durchlaufen, ohne am PDB-Drain
zu hängen. Zu prüfende Ansätze (Hypothesen, morgen verifizieren):

1. **Pre-destroy-Hook:** `null_resource` mit destroy-time `local-exec`, das vor
   dem Node-Pool-Delete die Blocker entfernt, z. B.
   `kubectl delete pdb --all -A` oder Flux suspendieren + HelmReleases
   deinstallieren. → Reihenfolge via `depends_on` erzwingen.
2. **Cluster statt Pool zuerst löschen:** Der separate
   `azurerm_kubernetes_cluster_node_pool.user` wird von Terraform *vor* dem
   Cluster gelöscht (mit laufenden PDBs). Alternative: keinen separaten
   User-Pool als eigene Resource führen, sondern nur `default_node_pool` — dann
   entfällt der problematische Einzel-Pool-Delete (der Cluster-Delete drained
   nicht pool-weise).
3. **AKS-Seitig Drain umgehen:** prüfen, ob der azurerm-Provider bzw. AKS ein
   „force delete / skip drain" für Agent-Pools unterstützt (API
   `ignore-pod-disruption-budget` bei `az aks nodepool delete` existiert —
   Provider-Äquivalent suchen).
4. **GitOps zuerst zurückrollen:** `flux uninstall` / Suspend vor `terraform
   destroy`, sodass keine PDB-behafteten Workloads mehr existieren.

**Aktuelle Einschätzung:** Ansatz **2** (nur `default_node_pool`, kein separater
User-Pool als eigene Resource) oder **1** (Pre-destroy `kubectl delete pdb`) sind
am robustesten. Morgen testen und in `infra/modules/aks/` umsetzen.

## 4. Audit-Log

`azure-activity-log.csv` (269 Zeilen, `2026-07-08T11:27–15:54Z`) — vollständiger
Azure-Activity-Log über den Lebenszyklus der Demo (Deploy → Betrieb → Teardown).
Enthält u. a.:

| Operation | Bedeutung |
|-----------|-----------|
| Get/Delete Managed Cluster, Delete Agent Pool | AKS-Lifecycle (inkl. der fehlgeschlagenen Pool-Löschung) |
| Create role assignment | RBAC-Zuweisungen (AcrPull, Cluster Admin, Secrets Officer) |
| Create or Update Load Balancer / NSG / Subnet | Netzwerk durch AKS + Terraform |
| List Storage Account Keys / Workspace Shared Keys | Terraform-State-Backend & Log Analytics |
| `'audit' / 'auditIfNotExists' Policy action` | Azure Policy Compliance-Checks |
| Register Subscription | Resource-Provider-Registrierung |

Auswertbar per KQL im Log-Analytics-Workspace oder direkt aus der CSV — belegt
Nachvollziehbarkeit („wer hat was wann getan", `Event initiated by`-Spalte).
