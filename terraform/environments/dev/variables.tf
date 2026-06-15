# ---------------------------------------------------------------------------
# Secrets (Epic 7). Sensitive values are supplied at apply time via
# TF_VAR_* environment variables or a tfvars file kept out of Git — never
# hardcoded here.
# ---------------------------------------------------------------------------
variable "openai_api_key" {
  description = "OpenAI API key for genai-service. Provide via TF_VAR_openai_api_key."
  type        = string
  sensitive   = true
}

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
  description = "Password or PAT for the config-server Git repository."
  type        = string
  default     = ""
  sensitive   = true
}
