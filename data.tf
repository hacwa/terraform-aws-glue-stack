data "aws_db_instance" "mysql" {
  db_instance_identifier = "${local.name_prefix}-mysql"
  depends_on             = [module.rds]

}

locals {
  # master_user_secret is a list with one element when AWS manages the secret
  rds_secret_arn = try(data.aws_db_instance.mysql.master_user_secret[0].secret_arn, "")
}
