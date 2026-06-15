# Jira Backlog — Petclinic Platform

## Epic 1 — Foundation & Remote State

### PetclinicPlatform1 — Terraform Directory Structure
Create the standard Terraform directory layout for this project.
**Acceptance Criteria:**
- terraform/bootstrap/ exists
- terraform/modules/ exists
- terraform/environments/dev/ exists
- terraform/environments/prod/ exists

### PetclinicPlatform2 — S3 State Bucket + DynamoDB Lock Table
**Acceptance Criteria:**
- S3 bucket: petclinic-tfstate-506261418156 in eu-central-1
- Versioning enabled
- AES256 encryption enabled
- All public access blocked
- DynamoDB table: petclinic-tfstate-lock
- Billing: PAY_PER_REQUEST
- Hash key: LockID (String)
- Bootstrap uses local state

### PetclinicPlatform3 — Backend Config for Dev
**Acceptance Criteria:**
- terraform/environments/dev/backend.hcl exists
- Points to petclinic-tfstate-506261418156
- Key: dev/terraform.tfstate
- Region: eu-central-1
- DynamoDB table: petclinic-tfstate-lock

### PetclinicPlatform4 — Backend Config for Prod
**Acceptance Criteria:**
- terraform/environments/prod/backend.hcl exists
- Key: prod/terraform.tfstate
- All other values same as dev

### PetclinicPlatform5 — AWS Provider and versions.tf
**Acceptance Criteria:**
- terraform/environments/dev/versions.tf exists
- terraform/environments/prod/versions.tf exists
- AWS provider ~> 5.0, region eu-central-1
- Terraform required version >= 1.6
- Default tags: Project=petclinic, ManagedBy=terraform, Environment=dev/prod

## Epic 2 — VPC & Networking

### PetclinicPlatform6 — Create VPC Module
**Acceptance Criteria:**
- terraform/modules/vpc/ exists with main.tf, variables.tf, outputs.tf
- VPC CIDR: 10.0.0.0/16
- 3 public subnets, 3 private subnets across eu-central-1a/b/c
- No NAT Gateway
- DNS hostnames and DNS support enabled
- Subnets tagged for EKS discovery

### PetclinicPlatform8 — Create Baseline Security Groups
**Acceptance Criteria:**
- Security group module in terraform/modules/vpc/
- Allow all egress
- Restrict ingress to known ports only

### PetclinicPlatform9 — Wire VPC Module into Dev
**Acceptance Criteria:**
- terraform/environments/dev/main.tf calls the VPC module
- Uses dev values from technical-spec.md
- terraform validate passes

### PetclinicPlatform10 — Wire VPC Module into Prod
**Acceptance Criteria:**
- terraform/environments/prod/main.tf calls the VPC module
- terraform validate passes

## Epic 2 — VPC & Networking

### PetclinicPlatform6 — VPC Module
Create reusable VPC module at terraform/modules/vpc/
**Acceptance Criteria:**
- terraform/modules/vpc/main.tf, variables.tf, outputs.tf, versions.tf exist
- VPC CIDR: 10.0.0.0/16, DNS hostnames and DNS support enabled
- Public Subnet A: 10.0.1.0/24 in eu-central-1a
- Public Subnet B: 10.0.2.0/24 in eu-central-1b
- Internet Gateway attached to VPC
- Route table with 0.0.0.0/0 → IGW for public subnets
- EKS subnet tags: kubernetes.io/cluster/{cluster-name}=shared, kubernetes.io/role/elb=1
- Outputs: vpc_id, public_subnet_ids, private_subnet_ids

### PetclinicPlatform8 — Baseline Security Groups
Create 4 security groups in the VPC module.
**Acceptance Criteria:**
- SG: EKS nodes — controls traffic between nodes and pods
- SG: RDS — port 3306, ingress only from EKS node SG
- SG: ALB — port 80/443 from 0.0.0.0/0, egress to EKS nodes
- SG: EKS cluster — control plane to node communication
- Security group rules as separate resources (avoid circular dependencies)
- Outputs: sg_eks_nodes_id, sg_rds_id, sg_alb_id, sg_eks_cluster_id

### PetclinicPlatform9 — Wire VPC Module into Dev
**Acceptance Criteria:**
- terraform/environments/dev/main.tf calls the VPC module
- Passes correct values from technical-spec.md
- terraform validate passes in dev

### PetclinicPlatform10 — Wire VPC Module into Prod
**Acceptance Criteria:**
- terraform/environments/prod/main.tf calls the VPC module
- terraform validate passes in prod

## Epic 3 — EKS Cluster

### PetclinicPlatform12 — EKS Cluster, IAM Role, OIDC Provider
**Acceptance Criteria:**
- EKS cluster named petclinic-eks-dev in eu-central-1
- Cluster IAM role with AmazonEKSClusterPolicy
- OIDC provider created for IRSA
- Public endpoint enabled
- Kubernetes version: 1.30

### PetclinicPlatform13 — Managed Node Group
**Acceptance Criteria:**
- Node group with t4g.small (ARM64/Graviton)
- Min: 2, Max: 4, Desired: 2
- Node IAM role with AmazonEKSWorkerNodePolicy, AmazonEKS_CNI_Policy, AmazonEC2ContainerRegistryReadOnly
- Nodes launch in VPC subnets

### PetclinicPlatform14 — kubectl Access Configuration
**Acceptance Criteria:**
- Output the aws eks update-kubeconfig command
- Region: eu-central-1
- Cluster name from module output

### PetclinicPlatform15 — Wire EKS Module into Dev
**Acceptance Criteria:**
- terraform/environments/dev/main.tf calls EKS module
- Passes vpc_id, subnet_ids, security group IDs from VPC module outputs
- terraform validate passes

### PetclinicPlatform16 — Deploy and Verify Dev EKS Cluster
**Acceptance Criteria:**
- terraform apply succeeds in dev
- kubectl get nodes shows nodes in Ready state
- OIDC provider visible in AWS console

### PetclinicPlatform17 — Wire EKS Module into Prod
**Acceptance Criteria:**
- terraform/environments/prod/main.tf calls EKS module
- terraform validate passes

### PetclinicPlatform84 — Managed Add-ons
**Acceptance Criteria:**
- CoreDNS addon installed with pinned version
- kube-proxy addon installed with pinned version
- vpc-cni addon installed with pinned version
- EBS CSI Driver addon installed with pinned version
- EBS CSI Driver has its own IRSA role with EC2 permissions
- All addon versions pinned (not latest)

## Epic 4 — Container Registry (ECR)

### PetclinicPlatform18 — ECR Module
Create reusable ECR module at terraform/modules/ecr/
**Acceptance Criteria:**
- terraform/modules/ecr/main.tf, variables.tf, outputs.tf, versions.tf exist
- 8 repositories: config-server, discovery-server, api-gateway,
  customers-service, visits-service, vets-service, genai-service, admin-server
- Naming: petclinic-dev/{service} and petclinic-prod/{service}
- Scan on push enabled for all repos
- Lifecycle policy: keep last 10 images

### PetclinicPlatform19 — Tag Immutability
**Acceptance Criteria:**
- Dev repos: tag immutability MUTABLE
- Prod repos: tag immutability IMMUTABLE
- Configured via variable passed from environment

### PetclinicPlatform20 — Wire ECR Module into Dev and Prod
**Acceptance Criteria:**
- terraform/environments/dev/main.tf calls ECR module
- terraform/environments/prod/main.tf calls ECR module
- terraform apply succeeds in both environments
- 8 repos visible in AWS ECR console

### PetclinicPlatform21 — ECR Login Helper Script
**Acceptance Criteria:**
- scripts/ecr-login.sh exists and is executable
- Authenticates Docker to ECR registry
- Works with aws configure credentials

### PetclinicPlatform85 — Build and Push ARM64 Docker Images
**Acceptance Criteria:**
- All 8 images built with --platform linux/arm64
- Images tagged and pushed to petclinic-dev/ repos
- Uses eclipse-temurin:17 as base image
- Build script at scripts/build-and-push.sh

## Epic 5 — Database (RDS MySQL)

### PetclinicPlatform22 — RDS Module
Create reusable RDS module at terraform/modules/rds/
**Acceptance Criteria:**
- terraform/modules/rds/main.tf, variables.tf, outputs.tf, versions.tf exist
- RDS instance: db.t4g.micro, MySQL 8.0
- Storage: 20GB gp2, encrypted at rest
- Single-AZ deployment (dev and prod)
- DB subnet group covering both VPC subnets
- Parameter group: MySQL 8.0 with custom settings
- Accessible only from EKS node security group on port 3306
- Random password generated via Terraform

### PetclinicPlatform23 — Database Credentials in Secrets Manager
**Acceptance Criteria:**
- Credentials stored in AWS Secrets Manager
- Secret contains: username, password, host, port, dbname
- Secret named: petclinic/dev/db-credentials
- Terraform creates and manages the secret
- No plaintext credentials in code or Git

### PetclinicPlatform24 — Database Initialization Strategy
**Acceptance Criteria:**
- Schema files sourced from spring-petclinic-microservices/src/main/resources/db/mysql/
- Init container strategy defined for customers-service, vets-service, visits-service
- Kubernetes Job manifest created for one-time schema initialization

### PetclinicPlatform25 — Wire RDS Module into Dev
**Acceptance Criteria:**
- terraform/environments/dev/main.tf calls RDS module
- Passes vpc_id, subnet_ids, security group IDs from VPC module outputs
- terraform validate passes in dev

### PetclinicPlatform26 — Deploy and Verify Dev RDS
**Acceptance Criteria:**
- terraform apply succeeds in dev
- RDS instance visible in AWS console
- Endpoint accessible from EKS pod on port 3306
- Credentials retrievable from Secrets Manager

### PetclinicPlatform27 — Wire RDS Module into Prod
**Acceptance Criteria:**
- terraform/environments/prod/main.tf calls RDS module
- terraform validate passes in prod

## Epic 6 — DNS & Ingress

### PetclinicPlatform28 — DNS Module
Create DNS module at terraform/modules/dns/
**Acceptance Criteria:**
- terraform/modules/dns/main.tf, variables.tf, outputs.tf, versions.tf exist
- Route 53 hosted zone looked up via data source (not created)
- ACM certificate created for domain
- DNS validation used for ACM certificate
- Certificate covers apex and wildcard: yourdomain.com, *.yourdomain.com

### PetclinicPlatform29 — AWS Load Balancer Controller
**Acceptance Criteria:**
- IRSA role created for Load Balancer Controller
- IAM policy allows creating/managing ALBs in EC2
- Helm chart installed: aws-load-balancer-controller v1.8.1
- CRDs downloaded using app version v2.8.1 URL
- Controller running in kube-system namespace

### PetclinicPlatform30 — Ingress Manifest
**Acceptance Criteria:**
- Kubernetes Ingress manifest created
- Annotation: kubernetes.io/ingress.class: alb
- Routes yourdomain.com → api-gateway service port 8080
- HTTPS termination at ALB
- HTTP redirects to HTTPS

### PetclinicPlatform31 — DNS A Record
**Acceptance Criteria:**
- Route 53 A record created pointing to ALB hostname
- Record type: A (alias)
- Points apex domain to ALB

### PetclinicPlatform32 — Wire DNS Module into Dev
**Acceptance Criteria:**
- terraform/environments/dev/main.tf calls DNS module
- Passes domain_name, vpc_id, certificate_arn
- terraform validate passes in dev

## Epic 7 — Secrets Management

### PetclinicPlatform33 — Secrets Manager Resources
**Acceptance Criteria:**
- Secret created: petclinic/dev/openai containing OPENAI_API_KEY
- Secret created: petclinic/dev/config-server containing Git credentials
- Secrets created via Terraform
- No plaintext values in code or Git

### PetclinicPlatform34 — Install External Secrets Operator
**Acceptance Criteria:**
- ESO installed via Helm on EKS
- Running in external-secrets namespace
- ClusterSecretStore created pointing to AWS Secrets Manager
- IRSA role attached to ESO service account

### PetclinicPlatform35 — ExternalSecret CR for RDS
**Acceptance Criteria:**
- ExternalSecret CR created in petclinic-dev namespace
- Syncs petclinic/dev/rds from Secrets Manager
- Creates Kubernetes Secret: petclinic-db-credentials
- Refresh interval: 1h

### PetclinicPlatform36 — ExternalSecret CR for OpenAI
**Acceptance Criteria:**
- ExternalSecret CR created in petclinic-dev namespace
- Syncs petclinic/dev/openai from Secrets Manager
- Creates Kubernetes Secret: openai-api-key
- Refresh interval: 1h

### PetclinicPlatform37 — IRSA Role for External Secrets Operator
**Acceptance Criteria:**
- IAM role created for ESO service account
- Role allows secretsmanager:GetSecretValue and secretsmanager:DescribeSecret
- Role trusts EKS OIDC provider
- Annotated on ESO Kubernetes service account

## Epic 6 — DNS & Ingress

### PetclinicPlatform28 — DNS Module
Create DNS module at terraform/modules/dns/
**Acceptance Criteria:**
- terraform/modules/dns/main.tf, variables.tf, outputs.tf, versions.tf exist
- Route 53 hosted zone looked up via data source (not created)
- ACM certificate created for domain
- DNS validation used for ACM certificate
- Certificate covers apex and wildcard

### PetclinicPlatform29 — AWS Load Balancer Controller
**Acceptance Criteria:**
- IRSA role created for Load Balancer Controller
- IAM policy allows creating/managing ALBs in EC2
- Helm chart version: 1.8.1
- CRDs use app version v2.8.1 URL
- Controller running in kube-system namespace

### PetclinicPlatform30 — Ingress Manifest
**Acceptance Criteria:**
- Kubernetes Ingress manifest created
- Annotation: kubernetes.io/ingress.class: alb
- Routes domain → api-gateway service port 8080
- HTTPS termination at ALB
- HTTP redirects to HTTPS

### PetclinicPlatform31 — DNS A Record
**Acceptance Criteria:**
- Route 53 A record pointing to ALB hostname
- Record type: A alias

### PetclinicPlatform32 — Wire DNS Module into Dev
**Acceptance Criteria:**
- terraform/environments/dev/main.tf calls DNS module
- terraform validate passes in dev

## Epic 8 — Kubernetes Manifests

### PetclinicPlatform38 — Namespaces Manifest
**Acceptance Criteria:**
- k8s/base/namespaces.yaml exists
- Creates petclinic-dev and petclinic-prod namespaces
- Namespaces labeled with project and environment tags

### PetclinicPlatform39 — Config Server Manifests
**Acceptance Criteria:**
- k8s/base/config-server/deployment.yaml exists
- k8s/base/config-server/service.yaml exists
- Port 8888, startupProbe/readinessProbe/livenessProbe all use /actuator/health
- No init containers (starts first)
- Full securityContext applied
- imagePullPolicy: Always

### PetclinicPlatform40 — Discovery Server Manifests
**Acceptance Criteria:**
- k8s/base/discovery-server/deployment.yaml exists
- k8s/base/discovery-server/service.yaml exists
- Port 8761
- Init container waits for config-server:8888/actuator/health
- Full probes and securityContext applied

### PetclinicPlatform41 — Domain Services Manifests
**Acceptance Criteria:**
- k8s/base/customers-service/, visits-service/, vets-service/ exist
- Ports 8081, 8082, 8083 respectively
- Init containers wait for config-server and discovery-server
- DB credentials from petclinic-db-credentials secret
- Full probes and securityContext applied

### PetclinicPlatform42 — GenAI Service Manifests
**Acceptance Criteria:**
- k8s/base/genai-service/deployment.yaml exists
- Port 8084
- OpenAI API key from openai-api-key secret
- Init containers wait for config-server and discovery-server
- Full probes and securityContext applied

### PetclinicPlatform43 — API Gateway Manifests
**Acceptance Criteria:**
- k8s/base/api-gateway/deployment.yaml exists
- Port 8080
- Init containers wait for config-server and discovery-server
- Full probes and securityContext applied

### PetclinicPlatform44 — Admin Server Manifests
**Acceptance Criteria:**
- k8s/base/admin-server/deployment.yaml exists
- Port 9090
- Init containers wait for config-server and discovery-server
- Full probes and securityContext applied

### PetclinicPlatform45 — Dev Overlay Patches
**Acceptance Criteria:**
- k8s/overlays/dev/kustomization.yaml exists
- 1 replica per service
- CPU request: 100m, Memory request: 256Mi
- No HPA, no PDB

### PetclinicPlatform46 — Prod Overlay Patches
**Acceptance Criteria:**
- k8s/overlays/prod/kustomization.yaml exists
- 2+ replicas per service
- CPU request: 250m, Memory request: 512Mi
- PDB configured for all services

### PetclinicPlatform47 — HPA for Prod
**Acceptance Criteria:**
- HPA configured for api-gateway, customers-service, visits-service, vets-service
- Min replicas: 2, Max replicas: 4
- CPU target: 70%

## Epic 9 — Helm Charts

### PetclinicPlatform107 — Generic Helm Chart
Create generic Helm chart at helm/petclinic-service/
**Acceptance Criteria:**
- helm/petclinic-service/Chart.yaml exists
- helm/petclinic-service/values.yaml exists with defaults
- templates/deployment.yaml — with init containers, probes, securityContext
- templates/service.yaml — ClusterIP
- templates/configmap.yaml
- templates/serviceaccount.yaml
- templates/hpa.yaml — conditional, only renders when autoscaling.enabled=true
- templates/pdb.yaml — conditional, only renders when pdb.enabled=true
- helm lint passes

### PetclinicPlatform108 — Per-Service Values Files
**Acceptance Criteria:**
- helm-values/config-server.yaml exists
- helm-values/discovery-server.yaml exists
- helm-values/api-gateway.yaml exists
- helm-values/customers-service.yaml exists
- helm-values/visits-service.yaml exists
- helm-values/vets-service.yaml exists
- helm-values/genai-service.yaml exists
- helm-values/admin-server.yaml exists
- Each file contains correct port, image, env vars, secret references
- Matches exactly the k8s/base/ manifests

### PetclinicPlatform109 — Per-Environment Values Files
**Acceptance Criteria:**
- helm-values/dev.yaml exists
- helm-values/prod.yaml exists
- Dev: 1 replica, CPU 100m, Memory 256Mi, HPA disabled
- Prod: 2 replicas, CPU 250m, Memory 512Mi, HPA enabled for correct services
- PDB enabled in prod

### PetclinicPlatform110 — Helm Validation
**Acceptance Criteria:**
- helm lint passes for all services
- helm template renders correct manifests for all 8 services
- kubectl apply --dry-run=client passes on rendered output
- scripts/validate-helm.sh exists and is executable

### PetclinicPlatform111 — Helm Chart Documentation
**Acceptance Criteria:**
- helm/petclinic-service/README.md exists
- Documents values hierarchy
- Documents deploy command for each service
- Documents how to add a new service

## Epic 10 — CI/CD Pipeline

### PETPLAT-49 — Build and Push Docker Images Workflow
**Acceptance Criteria:**
- .github/workflows/build-push.yml in app repo
- Triggers on push to main
- Uses dorny/paths-filter to detect changed services
- Matrix strategy — only builds changed services
- Builds linux/arm64 images using Docker Buildx and QEMU
- Authenticates to AWS using OIDC (no hardcoded keys)
- Image tags use 7-character commit SHA
- Fires repository_dispatch to platform repo after push

### PETPLAT-50 — Update Image Tags Workflow
**Acceptance Criteria:**
- .github/workflows/update-image-tags.yml in platform repo
- Triggered by repository_dispatch event type: app-image-built
- Uses yq to update image.tag in helm-values/{service}.yaml
- Updates only services that changed (from payload)
- Commits and pushes updated helm-values to platform repo

### PETPLAT-52 — OIDC Federation for GitHub Actions
**Acceptance Criteria:**
- terraform/modules/github-oidc/main.tf exists
- IAM OIDC provider created for token.actions.githubusercontent.com
- IAM role trusts app repo fork and main branch only
- Trust policy uses sts:AssumeRoleWithWebIdentity
- ECR-only permissions: GetAuthorizationToken, BatchCheckLayerAvailability,
  PutImage, and layer upload actions
- No wildcard permissions

### PETPLAT-53 — Reusable Workflow Templates
**Acceptance Criteria:**
- Reusable workflow steps extracted where appropriate
- Located in .github/workflows/reusable/

### PETPLAT-54 — Rollback Strategy Documentation
**Acceptance Criteria:**
- docs/rollback-runbook.md exists
- Documents how to roll back to a previous image SHA
- Documents how to revert helm-values changes

### PETPLAT-87 — Image Tag Update Mechanism
**Acceptance Criteria:**
- yq used to update image.tag in helm-values/{service}.yaml
- SHA passed via repository_dispatch payload
- Only changed services updated, not all 8
- PLATFORM_REPO_TOKEN secret documented
- Trivy scans image before push — fails on CRITICAL vulnerabilities

## Epic 11 — GitOps with ArgoCD

### PetclinicPlatform112 — ArgoCD Installation Manifests
**Acceptance Criteria:**
- k8s/argocd/install/namespace.yaml exists — creates argocd namespace
- k8s/argocd/install/install.yaml exists — downloaded from stable release
- File downloaded exactly as-is, not modified or regenerated

### PetclinicPlatform113 — Dev Application CRDs
**Acceptance Criteria:**
- k8s/argocd/applications/dev/{service}-dev.yaml exists for all 8 services
- metadata.name: {service}-dev
- metadata.namespace: argocd
- spec.source.repoURL: actual GitHub URL from git remote
- spec.source.targetRevision: main
- spec.source.path: helm/petclinic-service
- spec.source.helm.releaseName: {service} (no -dev suffix)
- spec.source.helm.valueFiles: [../../helm-values/{service}.yaml, ../../helm-values/dev.yaml]
- spec.destination.namespace: petclinic-dev
- syncPolicy.automated.prune: true
- syncPolicy.automated.selfHeal: true
- syncOptions: CreateNamespace=true, PruneLast=true, ApplyOutOfSyncOnly=true

### PetclinicPlatform114 — Prod Application CRDs
**Acceptance Criteria:**
- k8s/argocd/applications/prod/{service}-prod.yaml exists for all 8 services
- Same structure as dev but:
- spec.destination.namespace: petclinic-prod
- valueFiles use prod.yaml
- NO syncPolicy.automated block — manual sync only

### PetclinicPlatform115 — ArgoCD RBAC
**Acceptance Criteria:**
- k8s/argocd/argocd-rbac-cm.yaml exists
- admin role: full access to all apps and settings
- developer role: view all apps, sync dev only, no prod sync

### PetclinicPlatform116 — Test GitOps Loop
**Acceptance Criteria:**
- ArgoCD installed and running in argocd namespace
- All 8 dev apps show Synced and Healthy
- Image tag update in helm-values triggers auto-sync within 3 minutes
- Prod apps require manual sync

## Epic 12 — Observability

### PETPLAT-55 — Prometheus
**Acceptance Criteria:**
- k8s/base/observability/prometheus.yaml exists
- Deployment, Service, ConfigMap, PersistentVolumeClaim
- Scrapes exactly 5 services: api-gateway, customers-service, visits-service, vets-service, genai-service
- Scrape endpoint: /actuator/prometheus on correct port
- Scrape interval: 15s
- Alertmanager connected via alertmanager_config

### PETPLAT-56 — Grafana
**Acceptance Criteria:**
- k8s/base/observability/grafana.yaml exists
- Deployment, Service, ConfigMaps for datasources and dashboards
- Prometheus datasource: uid: prometheus, url: http://prometheus:9090
- Loki datasource: uid: loki, url: http://loki:3100
- Both datasources auto-provisioned with explicit uid fields
- PersistentVolumeClaim for dashboard storage

### PETPLAT-57 — Per-Service Grafana Dashboards
**Acceptance Criteria:**
- Dashboard panels include refId: A and datasource uid fields
- JVM metrics dashboard per service
- HTTP request rate and latency dashboards
- No Data panels due to missing uid or refId

### PETPLAT-58 — Alerting Rules
**Acceptance Criteria:**
- k8s/base/observability/alerting-rules.yaml exists
- PrometheusRule CRDs for all 5 alert rules:
  - High error rate: HTTP 5xx > threshold for 5 min
  - Pod restart loop: restarts > 5 in 15 min
  - High memory usage: > 80% of limit
  - Service down: no metrics for 2 min
  - Slow response time: P99 latency > 2s for 5 min

### PETPLAT-59 — Loki and FluentBit
**Acceptance Criteria:**
- k8s/base/observability/loki.yaml exists
- k8s/base/observability/fluentbit.yaml exists
- FluentBit DaemonSet with ServiceAccount
- FluentBit output points to http://loki.monitoring:3100
- Loki alert rules for error spike and OOM

### PETPLAT-60 — Zipkin
**Acceptance Criteria:**
- k8s/base/observability/zipkin.yaml exists
- Deployed in tracing namespace (not monitoring)
- Port 9411
- 5 instrumented services send traces to http://zipkin.tracing:9411/api/v2/spans
- MANAGEMENT_ZIPKIN_TRACING_ENDPOINT set in service ConfigMaps
- MANAGEMENT_TRACING_SAMPLING_PROBABILITY=1.0

### PETPLAT-103 — Alertmanager
**Acceptance Criteria:**
- k8s/base/observability/alertmanager.yaml exists
- Deployment, Service, ConfigMap with routing config
- At least one receiver configured
- Connected to Prometheus via alertmanager_config

## Epic 13 — Scaling & Cost

### PETPLAT-72 — Metrics Server
**Acceptance Criteria:**
- k8s/base/karpenter/metrics-server.yaml exists
- Downloaded from official manifest
- Required for HPA to function

### PETPLAT-73 — Karpenter IAM and Kubernetes Resources
**Acceptance Criteria:**
- terraform/modules/karpenter/main.tf exists
- IAM role for Karpenter controller (IRSA with OIDC trust policy)
- IAM policy with EC2/EKS/IAM/SQS/pricing permissions
- IAM instance profile: petclinic-{env}-karpenter-node-profile
- SQS interruption queue (20-minute visibility timeout)
- EventBridge rules for 4 events: spot interruption, rebalance, instance state change, scheduled change
- SQS resource policy allowing EventBridge to publish
- k8s/base/karpenter/nodepool.yaml exists
- NodePool: ARM64, t4g.small/t4g.medium, on-demand, CPU limit 8, memory 32Gi
- EC2NodeClass: AL2023, subnet/sg selector karpenter.sh/discovery
- Instance profile name matches Terraform output exactly

### PETPLAT-74 — NodePool Spot Override
**Acceptance Criteria:**
- k8s/base/karpenter/nodepool-spot-dev.yaml exists as separate file
- Capacity type: spot and on-demand
- Comment at top explaining when to apply

### PETPLAT-75 — AWS Budget Alerts
**Acceptance Criteria:**
- aws_budgets_budget resource in dev and prod environments
- Monthly budget: $100
- Alert thresholds: 50%, 80%, 100% of actual spend
- Email notification to var.budget_alert_email
- Notification type: ACTUAL not FORECASTED
