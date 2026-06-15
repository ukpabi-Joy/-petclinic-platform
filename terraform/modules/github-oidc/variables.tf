variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "petclinic"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "ecr_repository_arns" {
  description = "List of ECR repository ARNs to grant push access"
  type        = list(string)
}

variable "tags" {
  description = "Default tags"
  type        = map(string)
  default     = {}
}
