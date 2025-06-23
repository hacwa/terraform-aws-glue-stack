
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.5.2"

  identifier           = "${local.name_prefix}-mysql"
  engine               = "mysql"
  engine_version       = "8.0.36"
  family               = "mysql8.0"
  major_engine_version = "8.0"

  instance_class        = var.db_instance_type
  allocated_storage     = 20
  storage_encrypted     = true
  max_allocated_storage = 100

  skip_final_snapshot = true
  deletion_protection = false

  db_name  = var.db_name
  username = var.db_username

  manage_master_user_password = true

  multi_az                = true
  publicly_accessible     = true
  backup_retention_period = 7
  apply_immediately       = true



  create_db_subnet_group = true
  subnet_ids             = module.vpc.public_subnets

  vpc_security_group_ids = [aws_security_group.sg_rds_mysql.id]

  iam_database_authentication_enabled = true

  tags = var.tags
}
