locals {
  name = "${var.project}-${var.environment}"

  # Secret paths follow the petclinic/<env>/<name> convention also used by the
  # rds module (petclinic/<env>/db-credentials).
  openai_secret_name        = "${var.project}/${var.environment}/openai"
  config_server_secret_name = "${var.project}/${var.environment}/config-server"
}

# ---------------------------------------------------------------------------
# OpenAI API key (PetclinicPlatform33). External Secrets Operator syncs this
# into the openai-api-key K8s secret for genai-service. The value comes from a
# sensitive Terraform variable — never hardcoded.
# ---------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "openai" {
  name                    = local.openai_secret_name
  description             = "OpenAI API key for ${local.name} genai-service"
  recovery_window_in_days = var.secret_recovery_window_days

  tags = {
    Name = local.openai_secret_name
  }
}

resource "aws_secretsmanager_secret_version" "openai" {
  secret_id = aws_secretsmanager_secret.openai.id

  secret_string = jsonencode({
    OPENAI_API_KEY = var.openai_api_key
  })
}

# ---------------------------------------------------------------------------
# Config Server Git credentials (PetclinicPlatform33). Used by config-server
# to authenticate to its configuration Git repository. All values are
# sensitive Terraform variables.
# ---------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "config_server" {
  name                    = local.config_server_secret_name
  description             = "Git credentials for the ${local.name} config-server"
  recovery_window_in_days = var.secret_recovery_window_days

  tags = {
    Name = local.config_server_secret_name
  }
}

resource "aws_secretsmanager_secret_version" "config_server" {
  secret_id = aws_secretsmanager_secret.config_server.id

  secret_string = jsonencode({
    uri      = var.config_server_git_uri
    username = var.config_server_git_username
    password = var.config_server_git_password
  })
}
