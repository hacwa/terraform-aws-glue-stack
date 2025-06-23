output "db_endpoint" {
  description = "MySQL endpoint"
  value       = module.rds.db_instance_endpoint
}

output "rds_secret_arn" {
  description = "ARN of the AWS-managed master-password secret"
  value       = local.rds_secret_arn
}

output "bucket_name" {
  description = "Primary S3 bucket for raw data and scripts"
  value       = aws_s3_bucket.data.id
}

data "aws_secretsmanager_secret_version" "db_secret" {
  secret_id = module.rds.db_instance_master_user_secret_arn
}

output "rds_username" {
  sensitive = true
  value     = jsondecode(data.aws_secretsmanager_secret_version.db_secret.secret_string)["username"]
}

output "rds_password" {
  sensitive = true
  value     = jsondecode(data.aws_secretsmanager_secret_version.db_secret.secret_string)["password"]
}

output "project" {
  value = var.project
}
