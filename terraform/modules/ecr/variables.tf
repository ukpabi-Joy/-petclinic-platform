variable "project" {
  description = "Project name, used as the prefix for repository names."
  type        = string
  default     = "petclinic"
}

variable "environment" {
  description = "Environment name (dev / prod)."
  type        = string
}

variable "services" {
  description = "Service names; one ECR repository is created per service."
  type        = list(string)
  default = [
    "config-server",
    "discovery-server",
    "api-gateway",
    "customers-service",
    "visits-service",
    "vets-service",
    "genai-service",
    "admin-server",
  ]
}

variable "tag_mutability" {
  description = "Image tag mutability for the repositories: MUTABLE (dev) or IMMUTABLE (prod)."
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.tag_mutability)
    error_message = "tag_mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Whether to scan images for vulnerabilities on push."
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Number of most-recent images to retain; older images are expired by the lifecycle policy."
  type        = number
  default     = 10
}

variable "untagged_expiry_days" {
  description = "Expire untagged images older than this many days (operational cleanup, applied before the keep-last-N rule)."
  type        = number
  default     = 14
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key ARN for repository encryption. When null, ECR uses AES256 (AWS-managed). Immutable after creation."
  type        = string
  default     = null
}

variable "repository_policy_json" {
  description = "Optional ECR repository policy document (JSON) applied to every repository for resource-level least privilege. When null, no repository policy is attached and access is governed by caller IAM."
  type        = string
  default     = null
}
