# Kubernetes Manifests (Epic 8)

Kustomize base + dev/prod overlays for the eight Petclinic microservices.

```
k8s/
├── base/
│   ├── namespaces.yaml          # petclinic-dev + petclinic-prod (applied once, not in kustomization)
│   ├── kustomization.yaml       # aggregates all 8 services' deployment + service
│   ├── config-server/           # 8888 — no init container (starts first)
│   ├── discovery-server/        # 8761 — init: config-server
│   ├── customers-service/       # 8081 — init: config + discovery, DB creds
│   ├── visits-service/          # 8082 — init: config + discovery, DB creds
│   ├── vets-service/            # 8083 — init: config + discovery, DB creds
│   ├── genai-service/           # 8084 — init: config + discovery, OpenAI key
│   ├── api-gateway/             # 8080 — init: config + discovery
│   └── admin-server/            # 9090 — init: config + discovery
└── overlays/
    ├── dev/                     # ns petclinic-dev, 1 replica, 100m/256Mi, no HPA/PDB
    └── prod/                    # ns petclinic-prod, 2 replicas, 250m/512Mi, PDB (all) + HPA (4)
```

## Conventions (all deployments)

- **Startup order** enforced by `busybox:1.36` init containers running `wget`
  poll loops: `config-server` → `discovery-server` → everything else.
- **Probes:** `config-server` uses `/actuator/health` for startup, readiness and
  liveness. Every other service uses `/actuator/health` for startup,
  `/actuator/health/readiness` for readiness and `/actuator/health/liveness` for
  liveness.
- **securityContext** (pod): `runAsNonRoot`, `runAsUser: 1000`, `fsGroup: 1000`,
  `seccompProfile: RuntimeDefault`. (container): `allowPrivilegeEscalation: false`,
  `capabilities.drop: [ALL]`.
- **`imagePullPolicy: Always`** on every container.
- **Images:** the base uses placeholder names (`petclinic/<service>:latest`); each
  overlay's `images:` transformer rewrites them to the `petclinic-dev` /
  `petclinic-prod` ECR registry. CI bumps the tag per service.

## Secrets (from Epic 7 / External Secrets Operator)

- DB services read `petclinic-db-credentials` (`host`, `port`, `dbname`,
  `username`, `password`); the JDBC URL is assembled via `$(VAR)` interpolation.
- `genai-service` reads `openai-api-key` (`OPENAI_API_KEY`).

These Secrets exist in `petclinic-dev` only (Epic 7 was dev-scoped); create the
equivalent prod Secrets before deploying the prod overlay.

## Apply

```sh
# Once per cluster:
kubectl apply -f k8s/base/namespaces.yaml

# Per environment:
kubectl apply -k k8s/overlays/dev
kubectl apply -k k8s/overlays/prod
```

## Validate (offline)

```sh
kubectl kustomize k8s/overlays/dev   # render + structural check
kubectl kustomize k8s/overlays/prod
# Schema-validate the rendered output (kubeconform) or, against a reachable
# cluster: kubectl apply --dry-run=client -k k8s/overlays/<env>
```
