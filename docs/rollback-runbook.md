# Rollback Runbook

## Overview
This runbook describes how to roll back a failed deployment
in the Petclinic platform.

## Option 1 — Roll Back via Git (Recommended)

Revert the helm-values change in the platform repo:

```bash
git log --oneline helm-values/
git revert HEAD
git push origin main
```

ArgoCD will detect the change and automatically roll back
the affected services in dev. For prod, trigger a manual
sync in the ArgoCD UI.

## Option 2 — Roll Back via ArgoCD UI

1. Open ArgoCD UI:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
2. Go to https://localhost:8080
3. Find the affected application
4. Click History and Rollback
5. Select the previous healthy revision
6. Click Rollback

## Option 3 — Roll Back via kubectl

```bash
kubectl rollout history deployment/{service} -n petclinic-dev
kubectl rollout undo deployment/{service} -n petclinic-dev
kubectl rollout status deployment/{service} -n petclinic-dev
```

## Verifying a Rollback

```bash
kubectl get deployment {service} -n petclinic-dev \
  -o jsonpath='{.spec.template.spec.containers[0].image}'
kubectl get pods -n petclinic-dev -l app={service}
kubectl logs -n petclinic-dev -l app={service} --tail=50
```

## Prevention
- Never push directly to main in the app repo
- Always review the build-push workflow output before merging
- Monitor Grafana dashboards after every deployment
- Set up Alertmanager notifications for pod restart loops
