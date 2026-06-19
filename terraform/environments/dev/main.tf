module "vpc" {
  source = "../../modules/vpc"

  environment  = "dev"
  cluster_name = "petclinic-eks-dev"

  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]

  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

module "eks" {
  source = "../../modules/eks"

  environment  = "dev"
  cluster_name = "petclinic-eks-dev"

  kubernetes_version = "1.30"

  # All-public design (no NAT): nodes and control plane ENIs live in the
  # public subnets, which auto-assign public IPs and route via the IGW.
  subnet_ids                = module.vpc.public_subnet_ids
  cluster_security_group_id = module.vpc.sg_eks_cluster_id
  node_security_group_id    = module.vpc.sg_eks_nodes_id

  node_instance_types = ["t4g.small"]
  node_desired_size   = 3
  node_min_size       = 3
  node_max_size       = 4
}

output "eks_update_kubeconfig_command" {
  description = "Command to configure kubectl for the dev cluster."
  value       = module.eks.update_kubeconfig_command
}

module "ecr" {
  source = "../../modules/ecr"

  environment    = "dev"
  tag_mutability = "MUTABLE"
}

output "ecr_repository_urls" {
  description = "ECR repository URLs for the dev environment."
  value       = module.ecr.repository_urls
}

module "rds" {
  source = "../../modules/rds"

  environment = "dev"

  # RDS lives in the private subnets; the subnet group spans multiple AZs.
  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.vpc.sg_rds_id]

  instance_class    = "db.t4g.micro"
  engine_version    = "8.0"
  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true
  multi_az          = false

  db_name  = "petclinic"
  username = "petclinic"
  backup_retention_period = 0
}

output "rds_endpoint" {
  description = "RDS endpoint for the dev environment."
  value       = module.rds.db_endpoint
}

output "rds_secret_name" {
  description = "Secrets Manager secret holding the dev DB credentials."
  value       = module.rds.secret_name
}

# ---------------------------------------------------------------------------
# DNS & Ingress (Epic 6)
# ---------------------------------------------------------------------------
module "dns" {
  source = "../../modules/dns"

  environment = "dev"

  # Hosted zone already exists in Route 53; the module looks it up.
  domain_name = "joycloudsolution.online"
  vpc_id      = module.vpc.vpc_id

  # App host fronted by the ALB. The A-alias record is created once the ALB
  # exists — supply alb_dns_name/alb_zone_id then re-apply (see k8s/ingress).
  alias_record_names = ["petclinic.joycloudsolution.online"]
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN (apex + wildcard) for the dev ALB Ingress."
  value       = module.dns.certificate_arn
}

output "route53_zone_id" {
  description = "Route 53 hosted zone ID for the domain."
  value       = module.dns.zone_id
}

module "alb_controller" {
  source = "../../modules/alb-controller"

  environment  = "dev"
  cluster_name = module.eks.cluster_name

  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
}

output "alb_controller_role_arn" {
  description = "IRSA role ARN for the AWS Load Balancer Controller (dev)."
  value       = module.alb_controller.role_arn
}

# ---------------------------------------------------------------------------
# Secrets Management (Epic 7)
# ---------------------------------------------------------------------------
module "secrets" {
  source = "../../modules/secrets"

  environment = "dev"

  # Sensitive — sourced from TF_VAR_* / tfvars, never committed.
  openai_api_key             = var.openai_api_key
  config_server_git_uri      = var.config_server_git_uri
  config_server_git_username = var.config_server_git_username
  config_server_git_password = var.config_server_git_password
}

output "openai_secret_name" {
  description = "Secrets Manager secret holding the OpenAI API key (dev)."
  value       = module.secrets.openai_secret_name
}

output "config_server_secret_name" {
  description = "Secrets Manager secret holding the config-server Git credentials (dev)."
  value       = module.secrets.config_server_secret_name
}

# IRSA role letting the External Secrets Operator read the dev secrets.
module "external_secrets" {
  source = "../../modules/external-secrets"

  environment  = "dev"
  cluster_name = module.eks.cluster_name

  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
}

output "external_secrets_role_arn" {
  description = "IRSA role ARN for the External Secrets Operator (dev)."
  value       = module.external_secrets.role_arn
}

# GitHub OIDC — allows GitHub Actions to push to ECR
module "github_oidc" {
  source = "../../modules/github-oidc"

  environment        = "dev"
  project            = "petclinic"
  aws_account_id     = "506261418156"
  ecr_repository_arns = values(module.ecr.repository_arns)

  tags = {
    Project     = "petclinic"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC"
  value       = module.github_oidc.github_actions_role_arn
}
