# External Secrets

Syncs secrets from **AWS Secrets Manager** into Kubernetes Secrets using the
[External Secrets Operator](https://external-secrets.io) (ESO).

```
AWS Secrets Manager                 ESO (IRSA)            Kubernetes Secret
  petclinic/dev/db-credentials  ->  ExternalSecret   ->   petclinic-db-credentials (petclinic-dev)
  petclinic/dev/openai          ->  ExternalSecret   ->   openai-api-key           (petclinic-dev)
```

- **Operator:** External Secrets Operator (`external-secrets/external-secrets`)
- **Namespace:** `external-secrets`
- **Auth:** IRSA — the ESO service account assumes the IAM role created by
  `terraform/modules/external-secrets` (read-only Secrets Manager access).
- **Refresh interval:** `1h`

## Files

| File | Purpose |
|------|---------|
| `values.yaml` | Helm values for installing ESO with the IRSA-annotated service account. |
| `cluster-secret-store.yaml` | `ClusterSecretStore` pointing at AWS Secrets Manager (`eu-central-1`). |
| `externalsecret-rds.yaml` | `ExternalSecret` → `petclinic-db-credentials` (PetclinicPlatform35). |
| `externalsecret-openai.yaml` | `ExternalSecret` → `openai-api-key` (PetclinicPlatform36). |

> **RDS source path:** the spec calls the RDS secret `petclinic/dev/rds`. The
> `rds` Terraform module actually creates it at `petclinic/dev/db-credentials`
> (it owns the generated master password), so `externalsecret-rds.yaml`
> references that real name.

## Prerequisites

1. EKS cluster up with an IAM OIDC provider (the `eks` module creates one).
2. `terraform apply` in `environments/dev` so the secrets and the ESO IRSA role
   exist. Capture the role ARN:

   ```sh
   terraform -chdir=terraform/environments/dev output -raw external_secrets_role_arn
   ```

3. The `petclinic-dev` namespace exists (see `k8s/base/namespaces.yaml`).

## Install (PetclinicPlatform34)

```sh
# 1. Add the Helm repo.
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# 2. Install ESO into the external-secrets namespace with the IRSA role.
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets --create-namespace \
  --values values.yaml \
  --set-string serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$(terraform -chdir=../../../terraform/environments/dev output -raw external_secrets_role_arn)"

# 3. Wait for the operator to be ready, then create the store + ExternalSecrets.
kubectl -n external-secrets rollout status deploy/external-secrets

kubectl apply -f cluster-secret-store.yaml
kubectl apply -f externalsecret-rds.yaml
kubectl apply -f externalsecret-openai.yaml
```

## Verify

```sh
# Store should report Valid.
kubectl get clustersecretstore aws-secrets-manager

# ExternalSecrets should report SecretSynced.
kubectl -n petclinic-dev get externalsecret

# The synced Kubernetes secrets should exist.
kubectl -n petclinic-dev get secret petclinic-db-credentials openai-api-key
```
