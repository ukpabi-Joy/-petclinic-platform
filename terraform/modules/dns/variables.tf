variable "project" {
  description = "Project name, used as a prefix for resource names and tags."
  type        = string
  default     = "petclinic"
}

variable "environment" {
  description = "Environment name (dev / prod)."
  type        = string
}

variable "domain_name" {
  description = "Apex domain whose Route 53 hosted zone already exists (e.g. joycloudsolution.online)."
  type        = string
}

variable "vpc_id" {
  description = "VPC the workloads run in. Accepted for context/wiring; the hosted zone is public so it is not attached to the VPC."
  type        = string
  default     = null
}

variable "subject_alternative_names" {
  description = "Additional names on the ACM certificate. Defaults to the wildcard for the apex domain."
  type        = list(string)
  default     = null
}

variable "alias_record_names" {
  description = "Fully-qualified names to point at the ALB via A-alias records (e.g. petclinic.joycloudsolution.online). Defaults to the apex domain when empty."
  type        = list(string)
  default     = []
}

variable "alb_dns_name" {
  description = "DNS name of the ALB created by the AWS Load Balancer Controller. Leave null until the Ingress (and therefore the ALB) exists; the alias records are only created once this is set."
  type        = string
  default     = null
}

variable "alb_zone_id" {
  description = "Canonical hosted zone ID of the ALB, required for the A-alias target. Pair with alb_dns_name."
  type        = string
  default     = null
}
