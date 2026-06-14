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
  description = "Name of the EKS cluster the controller manages ALBs for."
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
  description = "Namespace the controller runs in."
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Service account the controller uses (must match the Helm release)."
  type        = string
  default     = "aws-load-balancer-controller"
}
