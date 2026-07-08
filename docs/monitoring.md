---
title: "Monitoring — Records & Nachweise (Live-Deployment)"
author: "Alex Benisch"
date: 2026-07-08
geometry: "margin=1.5cm"
papersize: a4
---

# Monitoring — Records & Nachweise

Aufgenommen am **2026-07-08** vom Live-Cluster `aks-devops-dev`
(Subscription `mercury`, Region `westeurope`, Kubernetes `v1.35.5`).

Das Monitoring läuft zweigleisig:

1. **Azure Container Insights** — Node-/Pod-Telemetrie in Log Analytics (via `oms_agent`
   im AKS-Terraform-Modul, out-of-cluster, ausfallsicher gegenüber Cluster-Problemen).
2. **kube-prometheus-stack** — Prometheus + Grafana + Alertmanager, per Flux (GitOps)
   in den Cluster deployt.

---

## 1. Azure Container Insights

| Feld | Wert |
|------|------|
| Aktiviert | `true` (AKS-Addon `omsagent`) |
| Log Analytics Workspace | `log-devops-dev` |
| Workspace Resource ID | `/subscriptions/6280aae8-…/resourceGroups/rg-devops-dev/providers/Microsoft.OperationalInsights/workspaces/log-devops-dev` |
| Aufbewahrung | 30 Tage (`retention_in_days`) |
| Lösung | `ContainerInsights(log-devops-dev)` |

DaemonSet `ama-logs` läuft auf allen Nodes und streamt Container-stdout/-stderr sowie
Node-Metriken nach Log Analytics (KQL-abfragbar im Portal).

---

## 2. kube-prometheus-stack — Komponenten (Live-Status)

HelmRelease `monitoring/kube-prometheus-stack` **Ready = True** (Chart `61.9.0`).

```
NAME                                                        READY   STATUS
alertmanager-kube-prometheus-stack-alertmanager-0           2/2     Running
kube-prometheus-stack-grafana-89b7b9966-p5t5b               3/3     Running
kube-prometheus-stack-kube-state-metrics-…                  1/1     Running
kube-prometheus-stack-operator-…                            1/1     Running
kube-prometheus-stack-prometheus-node-exporter (×3)         1/1     Running   # 1 pro Node
prometheus-kube-prometheus-stack-prometheus-0               2/2     Running
```

Node-Exporter läuft als DaemonSet auf allen **3** Nodes (System + 2× User nach
Cluster-Autoscaling).

---

## 3. Prometheus — Scrape-Health & Regeln

| Metrik | Wert |
|--------|------|
| Gesunde Scrape-Targets (`sum(up)`) | **25** |
| Rule-Groups gesamt | **36** |
| Alerting-Rules gesamt | **148** (Stack-Defaults + eigene) |

### Eigene Alert-Regeln (`observability/alert-rules.yaml`, Gruppe `app-health`)

Vom Prometheus-Operator übernommen (Selector `ruleSelectorNilUsesHelmValues: false`):

```
- PodCrashLooping          [inactive]  for=300s
- HighPodCpu               [inactive]  for=600s
- DeploymentReplicasMismatch [inactive] for=600s
```

`inactive` = keine Verletzung → Zielzustand. Jede Regel verweist in ihren
Annotations auf ein Runbook unter `observability/runbooks/`.

### Beispiel-Records (PromQL)

`count(kube_pod_info) by (namespace)` zum Aufnahmezeitpunkt:

```
app: 2        cert-manager: 3     flux-system: 4     ingress-nginx: 2
kyverno: 8    monitoring: 8       kube-system: 38    calico-system: 6
tigera-operator: 1
```

---

## 4. Alertmanager

- Pod `alertmanager-kube-prometheus-stack-alertmanager-0` **2/2 Running**.
- Zusätzlich Azure Monitor **Action Group** `ag-devops-dev` (E-Mail-Receiver
  `platform-oncall`) aus dem Terraform-`monitoring`-Modul als zweiter Alert-Kanal.

---

## 5. Grafana — Datasources & Dashboards (Records)

Grafana `11.1.3`, Pod **3/3 Running**, API-Health `database: ok`.

**Datasources** (aus dem Chart provisioniert):

| Name | Typ | Default | Health |
|------|-----|---------|--------|
| Prometheus | `prometheus` | ja | **OK** — „Successfully queried the Prometheus API" |
| Alertmanager | `alertmanager` | nein | wired auf `…-alertmanager:9093` |

**Provisionierte Dashboards: 27**, u. a.:

```
Kubernetes / Compute Resources / Cluster
Kubernetes / Compute Resources / Namespace (Pods)
Kubernetes / API server
Alertmanager / Overview
CoreDNS · etcd · Grafana Overview · Node Exporter / Nodes …
```

Das repo-eigene Dashboard `observability/dashboards/sample-api-overview.json`
wird über den Sidecar (Label `grafana_dashboard`) zusätzlich geladen.

---

## 6. Zugriff (lokal, ohne Ingress)

```bash
# Grafana (admin / prom-operator — Default des Charts, in Prod aus Key Vault)
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
#  -> http://localhost:3000

# Prometheus
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
#  -> http://localhost:9090/targets   /alerts   /rules

# Alertmanager
kubectl -n monitoring port-forward svc/kube-prometheus-stack-alertmanager 9093:9093
```

Grafana lädt Dashboards aus `observability/dashboards/` automatisch über den
Sidecar (Label `grafana_dashboard`), inkl. der Default-Kubernetes-Dashboards.

---

## 7. Fehlerbehebungs-Workflow (Talking Point)

`kubectl get events` → `kubectl describe pod` → `kubectl logs --previous` →
Grafana-Dashboard → Log-Analytics-KQL. Jeder Prometheus-Alert verlinkt auf ein
Runbook; kritische Alerts gehen zusätzlich an die Azure Action Group.
