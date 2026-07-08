# Runbook: PodCrashLooping

**Alert:** `PodCrashLooping` — ein Pod im Namespace `app` startet wiederholt neu.

## Sofort-Diagnose
```bash
NS=app
kubectl -n $NS get pods
kubectl -n $NS describe pod <pod>          # Events: OOMKilled? ImagePullBackOff?
kubectl -n $NS logs <pod> --previous       # Logs des abgestürzten Containers
```

## Häufige Ursachen & Fix
| Symptom (in Events/Logs) | Ursache | Fix |
|--------------------------|---------|-----|
| `OOMKilled` | Memory-Limit zu niedrig | `resources.limits.memory` erhöhen (deployment.yaml) |
| `ImagePullBackOff` | falscher Tag / ACR-Pull fehlt | Tag prüfen, AcrPull-Assignment (Terraform) prüfen |
| Liveness-Probe schlägt fehl | `/healthz` nicht erreichbar | Probe-Pfad/Port prüfen, `initialDelaySeconds` erhöhen |
| Exit direkt nach Start | App-Bug / fehlende Env | Logs lesen, Config/Secret prüfen |

## Rollback
GitOps-Prinzip: letzten funktionierenden Image-Tag wiederherstellen.
```bash
git revert <bad-commit>   # setzt Image-Tag im Manifest zurück; Flux deployt automatisch
```

## Eskalation
Wenn nach 15 Min nicht behoben → Platform-On-Call (Action Group `ag-devops-*`).
