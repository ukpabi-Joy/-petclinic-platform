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
  node_desired_size   = 2
  node_min_size       = 2
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
