output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "sg_eks_nodes_id" {
  description = "Security group ID for EKS nodes."
  value       = aws_security_group.eks_nodes.id
}

output "sg_rds_id" {
  description = "Security group ID for RDS."
  value       = aws_security_group.rds.id
}

output "sg_alb_id" {
  description = "Security group ID for the ALB."
  value       = aws_security_group.alb.id
}

output "sg_eks_cluster_id" {
  description = "Security group ID for the EKS control plane."
  value       = aws_security_group.eks_cluster.id
}
