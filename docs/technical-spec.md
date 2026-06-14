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
