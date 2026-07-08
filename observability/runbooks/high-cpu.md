# Runbook: HighPodCpu

**Alert:** `HighPodCpu` — ein Pod läuft >10 Min über 90 % seines CPU-Limits.

## Diagnose
```bash
NS=app
kubectl -n $NS top pods
kubectl -n $NS get hpa sample-api        # Skaliert der HPA bereits hoch?
```

## Bewertung
- **HPA skaliert & Last real** → ggf. `maxReplicas` erhöhen (hpa.yaml).
- **HPA am maxReplicas-Limit** → Kapazität prüfen; Node-Autoscaler (min/max_count im AKS-Modul).
- **Last unerwartet / eine Pod-Instanz** → Hot-Loop im Code? Logs & Traces prüfen.

## Kurzfristige Entlastung
```bash
kubectl -n $NS scale deployment/sample-api --replicas=4   # temporär, GitOps überschreibt
```
Dauerhaft: `maxReplicas`/`limits` im Manifest anpassen und committen.
