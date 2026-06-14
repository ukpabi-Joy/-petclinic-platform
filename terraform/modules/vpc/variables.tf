variable "project" {
  description = "Project name, used as the prefix for resource names."
  type        = string
  default     = "petclinic"
}

variable "environment" {
  description = "Environment name (dev / prod)."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name used for the kubernetes.io/cluster/<name> subnet discovery tag."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for the subnets. Public and private subnet lists are aligned to this order."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets, one per availability zone."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets, one per availability zone."
  type        = list(string)
}
