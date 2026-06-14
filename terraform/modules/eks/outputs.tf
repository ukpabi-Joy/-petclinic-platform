output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS control plane API server."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data for the cluster."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_version" {
  description = "Kubernetes version of the cluster."
  value       = aws_eks_cluster.this.version
}

output "cluster_security_group_id" {
  description = "Cluster security group managed by EKS."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider used for IRSA."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  description = "URL of the cluster OIDC issuer."
  value       = aws_iam_openid_connect_provider.this.url
}

output "node_role_arn" {
  description = "IAM role ARN assumed by the managed node group."
  value       = aws_iam_role.node.arn
}

output "ebs_csi_irsa_role_arn" {
  description = "IAM role ARN used by the EBS CSI driver (IRSA)."
  value       = aws_iam_role.ebs_csi.arn
}

# PetclinicPlatform14 — kubectl access configuration.
output "update_kubeconfig_command" {
  description = "Command to configure kubectl access to this cluster."
  value       = "aws eks update-kubeconfig --region eu-central-1 --name ${aws_eks_cluster.this.name}"
}
