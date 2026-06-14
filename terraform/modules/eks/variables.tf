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
  description = "Name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes control plane version."
  type        = string
  default     = "1.30"
}

variable "subnet_ids" {
  description = "Subnet IDs for the control plane ENIs and the managed node group."
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "Security group ID for the EKS control plane (from the VPC module)."
  type        = string
}

variable "node_security_group_id" {
  description = "Security group ID for the EKS worker nodes (from the VPC module)."
  type        = string
}

variable "endpoint_public_access" {
  description = "Whether the cluster API server endpoint is publicly accessible."
  type        = bool
  default     = true
}

# ----- Managed node group --------------------------------------------------
variable "node_instance_types" {
  description = "Instance types for the managed node group (t4g.small = ARM64 / Graviton)."
  type        = list(string)
  default     = ["t4g.small"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 4
}

# ----- Add-ons (versions pinned, not "latest") -----------------------------
variable "addon_versions" {
  description = "Pinned add-on versions, keyed by add-on name. Compatible with Kubernetes 1.30."
  type        = map(string)
  default = {
    vpc-cni            = "v1.18.3-eksbuild.3"
    coredns            = "v1.11.1-eksbuild.9"
    kube-proxy         = "v1.30.0-eksbuild.3"
    aws-ebs-csi-driver = "v1.33.0-eksbuild.1"
  }
}
