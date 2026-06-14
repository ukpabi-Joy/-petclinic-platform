module "vpc" {
  source = "../../modules/vpc"

  environment  = "prod"
  cluster_name = "petclinic-eks-prod"

  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]

  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

module "eks" {
  source = "../../modules/eks"

  environment  = "prod"
  cluster_name = "petclinic-eks-prod"

  kubernetes_version = "1.30"

  # All-public design (no NAT): nodes and control plane ENIs live in the
  # public subnets, which auto-assign public IPs and route via the IGW.
  subnet_ids                = module.vpc.public_subnet_ids
  cluster_security_group_id = module.vpc.sg_eks_cluster_id
  node_security_group_id    = module.vpc.sg_eks_nodes_id

  node_instance_types = ["t4g.small"]
  node_desired_size   = 2
  node_min_size       = 2
  node_max_size       = 4
}

output "eks_update_kubeconfig_command" {
  description = "Command to configure kubectl for the prod cluster."
  value       = module.eks.update_kubeconfig_command
}

module "ecr" {
  source = "../../modules/ecr"

  environment    = "prod"
  tag_mutability = "IMMUTABLE"
}

output "ecr_repository_urls" {
  description = "ECR repository URLs for the prod environment."
  value       = module.ecr.repository_urls
}

module "rds" {
  source = "../../modules/rds"

  environment = "prod"

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

  # Protect the prod database from accidental teardown.
  deletion_protection = true
  skip_final_snapshot = false
}

output "rds_endpoint" {
  description = "RDS endpoint for the prod environment."
  value       = module.rds.db_endpoint
}

output "rds_secret_name" {
  description = "Secrets Manager secret holding the prod DB credentials."
  value       = module.rds.secret_name
}
