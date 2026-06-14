# Technical Specification — Petclinic Platform

## AWS
- Account ID: 506261418156
- Region: eu-central-1
- Profile: default

## Naming Convention
- Project: petclinic
- Environment: dev / prod
- Pattern: petclinic-{component}-{env}

## Terraform State
- S3 Bucket: petclinic-tfstate-506261418156
- DynamoDB Table: petclinic-tfstate-lock
- State key pattern: {env}/terraform.tfstate

## Networking
- VPC CIDR: 10.0.0.0/16
- Private Subnets: 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24
- Public Subnets: 10.0.101.0/24, 10.0.102.0/24, 10.0.103.0/24
- Availability Zones: eu-central-1a, eu-central-1b, eu-central-1c
- No NAT Gateway (cost saving)

## EKS
- Cluster name: petclinic-eks-dev
- Kubernetes version: 1.30
- Node type: t4g.small (Graviton, free trial until Dec 2026)
- Min nodes: 1, Max nodes: 3, Desired: 2

## RDS
- Instance: db.t4g.micro
- Engine: MySQL 8.0
- DB name: petclinic
- Multi-AZ: false (dev), true (prod)

## ECR
- Repos (8): config-server, discovery-server, api-gateway,
  customers-service, visits-service, vets-service,
  genai-service, admin-server

## Terraform
- Required version: >= 1.6
- AWS provider: ~> 5.0
- Default tags:
    Project: petclinic
    ManagedBy: terraform
    Environment: dev

## VPC Network Design
- VPC CIDR: 10.0.0.0/16
- Private Subnets: 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24
- Public Subnets: 10.0.101.0/24, 10.0.102.0/24, 10.0.103.0/24
- Availability Zones: eu-central-1a, eu-central-1b, eu-central-1c
- No NAT Gateway
- Enable DNS hostnames and DNS support
- Tag private subnets: kubernetes.io/role/internal-elb=1
- Tag public subnets: kubernetes.io/role/elb=1

## Security Groups
- Allow all egress (0.0.0.0/0)
- Ingress: 443 (HTTPS), 80 (HTTP) from 0.0.0.0/0
- Ingress: 8080-9090 within VPC CIDR only

## VPC Network Design
- VPC CIDR: 10.0.0.0/16
- DNS hostnames: enabled
- DNS support: enabled
- Design: all-public subnets (no NAT Gateway — cost saving)
- Public Subnet A: 10.0.1.0/24 — eu-central-1a
- Public Subnet B: 10.0.2.0/24 — eu-central-1b
- Internet Gateway: attached to VPC
- Route table: 0.0.0.0/0 → IGW for all public subnets
- EKS subnet tags:
    kubernetes.io/cluster/petclinic-eks-dev: shared
    kubernetes.io/role/elb: "1"

## Security Groups
- SG eks-nodes: controls node-to-node and node-to-pod traffic
- SG rds: port 3306 ingress from eks-nodes SG only
- SG alb: port 80/443 ingress from 0.0.0.0/0, egress to eks-nodes
- SG eks-cluster: control plane to node communication
- All SGs: allow all egress
- Security group rules defined as separate aws_security_group_rule resources

## EKS Cluster
- Cluster name: petclinic-eks-dev (dev), petclinic-eks-prod (prod)
- Kubernetes version: 1.30
- Endpoint: public
- Region: eu-central-1
- Node type: t4g.small (ARM64/Graviton)
- Min nodes: 2, Max nodes: 4, Desired: 2
- Free trial until Dec 2026

## IRSA Roles
- OIDC provider: created from EKS cluster OIDC issuer URL
- EBS CSI Driver: needs IRSA role with AmazonEBSCSIDriverPolicy
- Future services: External Secrets Operator, AWS Load Balancer Controller
