output "repository_urls" {
  description = "Map of service name to ECR repository URL."
  value       = { for svc, repo in aws_ecr_repository.this : svc => repo.repository_url }
}

output "repository_arns" {
  description = "Map of service name to ECR repository ARN."
  value       = { for svc, repo in aws_ecr_repository.this : svc => repo.arn }
}

output "repository_names" {
  description = "Map of service name to ECR repository name."
  value       = { for svc, repo in aws_ecr_repository.this : svc => repo.name }
}

output "registry_id" {
  description = "AWS account ID that owns the registry (shared by all repositories)."
  value       = values(aws_ecr_repository.this)[0].registry_id
}
