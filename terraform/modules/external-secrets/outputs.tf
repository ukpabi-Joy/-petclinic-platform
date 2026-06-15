output "role_arn" {
  description = "ARN of the IRSA role for the External Secrets Operator. Annotate the ESO service account with this."
  value       = aws_iam_role.this.arn
}

output "policy_arn" {
  description = "ARN of the IAM policy granting Secrets Manager read access."
  value       = aws_iam_policy.this.arn
}

output "namespace" {
  description = "Namespace the operator runs in."
  value       = var.namespace
}

output "service_account_name" {
  description = "Service account name the IRSA role is scoped to."
  value       = var.service_account_name
}

output "service_account_annotation" {
  description = "Annotation to set on the ESO service account to enable IRSA."
  value       = { "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn }
}
