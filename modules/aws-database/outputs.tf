output "host" {
  description = "Instance address."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Instance port."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Database Presponsieve uses."
  value       = aws_db_instance.this.db_name
}

output "username" {
  description = "Application database user."
  value       = aws_db_instance.this.username
}

output "password_secret_arn" {
  description = "Secrets Manager ARN holding the password. Pass to the services module."
  value       = aws_secretsmanager_secret.db_password.arn
}

output "password_secret_name" {
  description = "Secrets Manager secret name."
  value       = aws_secretsmanager_secret.db_password.name
}

output "security_group_id" {
  description = "Security group guarding the instance."
  value       = aws_security_group.database.id
}

output "kms_key_arn" {
  description = "KMS key encrypting the instance and its secret."
  value       = aws_kms_key.rds.arn
}
