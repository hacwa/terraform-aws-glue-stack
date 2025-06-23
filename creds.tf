################################################################################
#  Secrets Manager (RDS creds)
################################################################################

resource "aws_secretsmanager_secret" "rds_creds" {
  name = "${var.project}-rds-creds-${random_id.suffix.hex}"
  tags = var.tags
}

resource "random_password" "db_password" {
  length  = 20
  special = true
}

resource "aws_secretsmanager_secret_version" "rds_creds_version" {
  secret_id     = aws_secretsmanager_secret.rds_creds.id
  secret_string = jsonencode({
    username = "glue_admin"
    password = random_password.db_password.result
  })
}

resource "random_id" "suffix" {
  byte_length = 2
}
