# Runbook: DeploymentReplicasMismatch

**Alert:** `DeploymentReplicasMismatch` — ein Deployment hat >10 Min nicht alle
Replicas verfügbar (Rollout hängt).

## Diagnose
```bash
NS=app
kubectl -n $NS rollout status deployment/sample-api --timeout=30s
kubectl -n $NS get pods -l app=sample-api
kubectl -n $NS describe deployment sample-api
```

## Häufige Ursachen
- **Pending Pods** → keine schedulebaren Nodes (Ressourcen/Node-Autoscaler prüfen).
- **Readiness-Probe rot** → neue Version wird nie „ready"; Probe/Endpoint prüfen.
- **Admission-Reject (Kyverno)** → Manifest verstößt gegen Policy (non-root / ACR-only).
  ```bash
  kubectl -n $NS get events --field-selector reason=PolicyViolation
  ```

## Rollback
```bash
kubectl -n $NS rollout undo deployment/sample-api   # sofortiger Notfall-Rollback
git revert <bad-commit>                             # sauberer GitOps-Weg (Flux reconciled)
```
