# Database initialization

Strategy for initializing the shared `petclinic` MySQL schema on the RDS
instance provisioned by `terraform/modules/rds`.

## Components

| File | Purpose |
|------|---------|
| `schema-configmap.yaml` | ConfigMap `petclinic-db-schema` holding the canonical Petclinic MySQL DDL (owners, pets, types, vets, specialties, vet_specialties, visits). |
| `db-init-job.yaml` | One-time Kubernetes Job that applies the schema to RDS. |
| `init-containers.yaml` | Strategic-merge patches adding a `wait-for-db` init container to customers-service, vets-service and visits-service. |

## Source of truth

The schema is sourced from the application repo:

```
spring-petclinic-microservices/src/main/resources/db/mysql/
```

`schema-configmap.yaml` is a checked-in snapshot of that DDL. Regenerate it
when the upstream schema changes:

```sh
kubectl create configmap petclinic-db-schema -n petclinic-dev \
  --from-file=schema.sql=spring-petclinic-microservices/src/main/resources/db/mysql/schema.sql \
  --dry-run=client -o yaml > k8s/database/schema-configmap.yaml
```

## Credentials

Both the Job and the init containers read DB connection details from the
`petclinic-db-credentials` Kubernetes Secret, which External Secrets Operator
syncs from the Secrets Manager secret `petclinic/<env>/db-credentials` created
by the RDS Terraform module (keys: `username`, `password`, `host`, `port`,
`dbname`). No plaintext credentials live in these manifests.

## Order of operations

1. `terraform apply` the RDS module (creates the instance + Secrets Manager secret).
2. Ensure ESO has synced `petclinic-db-credentials` into the `petclinic-dev` namespace.
3. `kubectl apply -f k8s/database/schema-configmap.yaml`
4. `kubectl apply -f k8s/database/db-init-job.yaml` — runs once, applies the schema.
5. Deploy the services with the `init-containers.yaml` patches so each Pod
   blocks until the database is reachable before the app container starts.
