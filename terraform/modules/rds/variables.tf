variable "project" {
  description = "Project name, used as a prefix for resource names."
  type        = string
  default     = "petclinic"
}

variable "environment" {
  description = "Environment name (dev / prod)."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the DB subnet group. RDS requires subnets in at least two AZs."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "subnet_ids must contain at least two subnets in different availability zones."
  }
}

variable "vpc_security_group_ids" {
  description = "Security group IDs attached to the DB instance (the RDS SG that allows 3306 from EKS nodes only)."
  type        = list(string)
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "engine_version" {
  description = "MySQL engine version."
  type        = string
  default     = "8.0"
}

variable "parameter_group_family" {
  description = "Parameter group family matching the engine version."
  type        = string
  default     = "mysql8.0"
}

variable "allocated_storage" {
  description = "Allocated storage in GB."
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "Storage type for the instance."
  type        = string
  default     = "gp2"
}

variable "storage_encrypted" {
  description = "Whether storage is encrypted at rest."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key ARN for storage encryption. When null, the AWS-managed RDS key is used."
  type        = string
  default     = null
}

variable "multi_az" {
  description = "Whether to deploy the instance across multiple AZs. Single-AZ in dev and prod per the cost-optimization spec."
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Name of the initial database created on the instance."
  type        = string
  default     = "petclinic"
}

variable "username" {
  description = "Master username for the database."
  type        = string
  default     = "petclinic"
}

variable "port" {
  description = "Port the database listens on."
  type        = number
  default     = 3306
}

variable "db_parameters" {
  description = "Custom MySQL parameters applied via the parameter group."
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    { name = "character_set_server", value = "utf8mb4" },
    { name = "collation_server", value = "utf8mb4_unicode_ci" },
    { name = "max_connections", value = "150" },
  ]
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection on the instance."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot when the instance is destroyed."
  type        = bool
  default     = true
}

variable "secret_recovery_window_days" {
  description = "Recovery window for the Secrets Manager secret. 0 forces immediate deletion (useful for dev tear-down)."
  type        = number
  default     = 7
}
