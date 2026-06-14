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
