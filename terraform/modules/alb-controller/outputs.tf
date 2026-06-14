output "role_arn" {
  description = "ARN of the IRSA role for the AWS Load Balancer Controller. Annotate the controller's service account with this."
  value       = aws_iam_role.this.arn
}

output "policy_arn" {
  description = "ARN of the IAM policy granting ALB management permissions."
  value       = aws_iam_policy.this.arn
}

output "namespace" {
  description = "Namespace the controller runs in."
  value       = var.namespace
}

output "service_account_name" {
  description = "Service account name the IRSA role is scoped to."
  value       = var.service_account_name
}

output "service_account_annotation" {
  description = "Annotation to set on the controller's service account to enable IRSA."
  value       = { "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn }
}
