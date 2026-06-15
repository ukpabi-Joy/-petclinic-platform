# petclinic-service Helm chart (Epic — Helm Charts)

A single **generic** chart used to deploy every Spring Petclinic microservice.
Instead of one chart per service, the per-service differences (name, port, env,
init containers) live in values files under [`helm-values/`](../../helm-values),
and the per-environment differences (replicas, resources, HPA/PDB) live in
`helm-values/dev.yaml` and `helm-values/prod.yaml`.

This chart is the Helm equivalent of the Kustomize manifests under
[`k8s/base/`](../../k8s/base) and [`k8s/overlays/`](../../k8s/overlays); rendered
output is intentionally equivalent (same ports, env, probes, init containers,
securityContext, resources, replica counts, HPA targets and PDB settings).

## Layout

```
helm/petclinic-service/
├── Chart.yaml
├── values.yaml                 # defaults (probes, securityContext, resources, image)
└── templates/
    ├── _helpers.tpl            # name + label helpers
    ├── deployment.yaml         # init containers, probes, securityContext, env
    ├── service.yaml            # ClusterIP
    ├── configmap.yaml          # conditional — renders only when .Values.config is set
    ├── serviceaccount.yaml     # conditional — renders when serviceAccount.create
    ├── hpa.yaml                # conditional — renders when autoscaling.enabled
    └── pdb.yaml                # conditional — renders when pdb.enabled

helm-values/
├── config-server.yaml          # per-service (PetclinicPlatform108)
├── discovery-server.yaml
├── customers-service.yaml
├── visits-service.yaml
├── vets-service.yaml
├── genai-service.yaml
├── api-gateway.yaml
├── admin-server.yaml
├── dev.yaml                    # per-environment (PetclinicPlatform109)
└── prod.yaml
```

## Values hierarchy

Values are merged left-to-right by `helm -f`; **later files win** (maps are
deep-merged, lists are replaced):

```
values.yaml  →  helm-values/{service}.yaml  →  helm-values/{env}.yaml
   defaults         service identity              env sizing + toggles
```

| Concern | Set in | Notes |
|---|---|---|
| probes, securityContext, image limits, init busybox image | `values.yaml` | shared defaults |
| `nameOverride`, `image.repository`, `service.port`, `env`, `initContainers` | `{service}.yaml` | per service |
| `image.tag` | `{service}.yaml` | bumped by CI (`yq`) |
| `replicaCount`, `resources.requests`, `image.registry` | `{env}.yaml` | dev vs prod |
| `pdb.enabled` | `prod.yaml` | all services in prod |
| `autoscaling.enabled` | `{service}.yaml` (=true for the 4 scalable) + forced off by `dev.yaml` | prod-only, selective |

### How selective HPA works

The four HPA-eligible services (`api-gateway`, `customers-service`,
`visits-service`, `vets-service`) set `autoscaling.enabled: true` in their own
values file. `dev.yaml` sets `autoscaling.enabled: false`, which (being applied
last) forces HPA off for **every** service in dev. `prod.yaml` deliberately does
**not** set `autoscaling.enabled`, so each service's own value decides — giving
HPA for exactly those four services in prod and none in dev. The image registry
works the same way: `image.repository` (the service name) comes from the service
file and `image.registry` (the dev/prod ECR prefix) from the env file.

## Deploy

```sh
# Dev — into namespace petclinic-dev:
helm upgrade --install <service> helm/petclinic-service \
  -f helm-values/<service>.yaml \
  -f helm-values/dev.yaml \
  -n petclinic-dev

# Prod — into namespace petclinic-prod:
helm upgrade --install <service> helm/petclinic-service \
  -f helm-values/<service>.yaml \
  -f helm-values/prod.yaml \
  -n petclinic-prod
```

Per service (dev shown; swap `dev` → `prod` and the namespace for production):

```sh
helm upgrade --install config-server    helm/petclinic-service -f helm-values/config-server.yaml    -f helm-values/dev.yaml -n petclinic-dev
helm upgrade --install discovery-server helm/petclinic-service -f helm-values/discovery-server.yaml -f helm-values/dev.yaml -n petclinic-dev
helm upgrade --install customers-service helm/petclinic-service -f helm-values/customers-service.yaml -f helm-values/dev.yaml -n petclinic-dev
helm upgrade --install visits-service   helm/petclinic-service -f helm-values/visits-service.yaml   -f helm-values/dev.yaml -n petclinic-dev
helm upgrade --install vets-service     helm/petclinic-service -f helm-values/vets-service.yaml     -f helm-values/dev.yaml -n petclinic-dev
helm upgrade --install genai-service    helm/petclinic-service -f helm-values/genai-service.yaml    -f helm-values/dev.yaml -n petclinic-dev
helm upgrade --install api-gateway      helm/petclinic-service -f helm-values/api-gateway.yaml      -f helm-values/dev.yaml -n petclinic-dev
helm upgrade --install admin-server     helm/petclinic-service -f helm-values/admin-server.yaml     -f helm-values/dev.yaml -n petclinic-dev
```

> The namespaces and the `petclinic-db-credentials` / `openai-api-key` Secrets
> (External Secrets Operator, Epic 7) must exist before deploying. The ESO
> secrets currently exist in `petclinic-dev` only — create the prod equivalents
> before deploying the prod release.

## Validate

```sh
scripts/validate-helm.sh
```

Runs `helm lint` and `helm template` for all 8 services × {dev, prod}, and — when
a cluster is reachable — `kubectl apply --dry-run=client` on the rendered output.
The dry-run is skipped automatically when no cluster is reachable.

## Adding a new service

1. Create `helm-values/<new-service>.yaml` with:
   - `nameOverride: <new-service>` and `image.repository: <new-service>`
   - `service.port: <port>`
   - the `env` list (plain values and/or `secretKeyRef` entries)
   - `initContainers` for any startup dependencies (each entry is
     `{name, host, port, path}`, rendered as a busybox wget poll loop)
   - `autoscaling.enabled: true` **only** if the service should scale in prod
2. If it needs a dedicated ConfigMap, populate the `config:` map (key/value);
   it is then exposed to the container via `envFrom`.
3. Deploy with the two `-f` flags shown above. No chart changes are required —
   the generic chart already covers Deployment, Service, ConfigMap,
   ServiceAccount, HPA and PDB.

## Differences from `k8s/base/`

- The chart creates a **dedicated ServiceAccount** per service
  (`serviceAccount.create: true`); the raw base manifests used the namespace
  `default` ServiceAccount. This is additive (set `serviceAccount.create: false`
  to match the base exactly).
- A `ConfigMap` template exists but renders nothing for the current services
  (their env is inline, matching the base). It is available for future config.
