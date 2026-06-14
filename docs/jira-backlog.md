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
