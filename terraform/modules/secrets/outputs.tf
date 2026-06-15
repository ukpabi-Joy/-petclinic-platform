output "openai_secret_arn" {
  description = "ARN of the OpenAI Secrets Manager secret."
  value       = aws_secretsmanager_secret.openai.arn
}

output "openai_secret_name" {
  description = "Name (path) of the OpenAI Secrets Manager secret."
  value       = aws_secretsmanager_secret.openai.name
}

output "config_server_secret_arn" {
  description = "ARN of the config-server Git credentials secret."
  value       = aws_secretsmanager_secret.config_server.arn
}

output "config_server_secret_name" {
  description = "Name (path) of the config-server Git credentials secret."
  value       = aws_secretsmanager_secret.config_server.name
}
