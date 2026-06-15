variable "project" {
  description = "Project name, used as a prefix for resource names and tags."
  type        = string
  default     = "petclinic"
}

variable "environment" {
  description = "Environment name (dev / prod)."
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster the operator runs in."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the cluster IAM OIDC provider (from the eks module)."
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the cluster OIDC issuer, e.g. oidc.eks.<region>.amazonaws.com/id/<id> (from the eks module; with or without the https:// prefix)."
  type        = string
}

variable "namespace" {
  description = "Namespace the External Secrets Operator runs in."
  type        = string
  default     = "external-secrets"
}

variable "service_account_name" {
  description = "Service account ESO uses (must match the Helm release / ClusterSecretStore)."
  type        = string
  default     = "external-secrets"
}

# ---------------------------------------------------------------------------
# Secrets the role may read. Defaults to every secret under the project's
# environment path (petclinic/<env>/*), which covers db-credentials, openai,
# and config-server. Override to tighten or widen the scope.
# ---------------------------------------------------------------------------
variable "secret_resource_arns" {
  description = "List of Secrets Manager ARNs (wildcards allowed) the ESO role may read. Defaults to all secrets under petclinic/<env>/."
  type        = list(string)
  default     = null
}
