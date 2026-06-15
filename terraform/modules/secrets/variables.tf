variable "project" {
  description = "Project name, used as a prefix for resource names."
  type        = string
  default     = "petclinic"
}

variable "environment" {
  description = "Environment name (dev / prod)."
  type        = string
}

# ---------------------------------------------------------------------------
# OpenAI — consumed by genai-service via the openai-api-key K8s secret.
# Sensitive and never hardcoded: supply via TF_VAR_openai_api_key or a tfvars
# file kept out of Git. No default, so a value must be provided explicitly.
# ---------------------------------------------------------------------------
variable "openai_api_key" {
  description = "OpenAI API key stored at petclinic/<env>/openai. Provide via TF_VAR_openai_api_key; never commit a value."
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Config Server Git credentials — used by config-server to pull the config
# repository. Optional (default empty) so the secret can be created and
# populated later. All sensitive.
# ---------------------------------------------------------------------------
variable "config_server_git_uri" {
  description = "Git repository URI the config-server reads configuration from."
  type        = string
  default     = ""
}

variable "config_server_git_username" {
  description = "Username for the config-server Git repository."
  type        = string
  default     = ""
  sensitive   = true
}

variable "config_server_git_password" {
  description = "Password or personal access token for the config-server Git repository."
  type        = string
  default     = ""
  sensitive   = true
}

variable "secret_recovery_window_days" {
  description = "Recovery window for the Secrets Manager secrets. 0 forces immediate deletion (useful for dev tear-down)."
  type        = number
  default     = 7
}
