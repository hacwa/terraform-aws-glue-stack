terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}

################################################################################
# Networking (VPC, subnets, NAT, endpoints)
################################################################################


# --- Interface & Gateway VPC Endpoints (keep traffic in VPC) ---------------
module "endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.5.2"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags            = var.tags
    }
    glue = {
      service             = "glue"
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [module.vpc.default_security_group_id]
      private_dns_enabled = true
      tags                = var.tags
    }
    secretsmanager = {
      service             = "secretsmanager"
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [module.vpc.default_security_group_id]
      private_dns_enabled = true
      tags                = var.tags
    }
  }
}

################################################################################
# Security Groups
################################################################################
resource "aws_security_group" "glue_jobs" {
  name        = "${var.project}-glue-sg"
  description = "Glue jobs egress‑only security group"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg"
  description = "Allow MySQL traffic from Glue"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "MySQL from Glue security group"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.glue_jobs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

################################################################################
# S3 Data Lake Bucket
################################################################################
resource "random_string" "suffix" {
  length  = 6
  lower   = true
  special = false
}

resource "aws_s3_bucket" "data" {
  bucket        = "${var.project}-bucket-${random_string.suffix.result}"
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

################################################################################
# IAM (Glue service‑role + least‑priv policy)
################################################################################
# Trust policy
data "aws_iam_policy_document" "glue_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "glue" {
  name               = "${var.project}-glue-role"
  assume_role_policy = data.aws_iam_policy_document.glue_trust.json
  tags               = var.tags
}

# AWS managed baseline policy
resource "aws_iam_role_policy_attachment" "glue_managed" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Custom least‑privilege policy
data "aws_iam_policy_document" "glue_custom" {
  statement {
    sid     = "S3DataLake"
    actions = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resources = [aws_s3_bucket.data.arn, "${aws_s3_bucket.data.arn}/*"]
  }
  statement {
    sid       = "GlueCatalog"
    actions   = ["glue:*Database*", "glue:*Table*", "glue:GetConnection", "glue:CreateConnection"]
    resources = ["*"]
  }
  statement {
    sid       = "SecretsManager"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [aws_secretsmanager_secret.rds_creds.arn]
  }
  statement {
    sid     = "Logs"
    actions = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "glue_custom" {
  name   = "${var.project}-glue-custom"
  policy = data.aws_iam_policy_document.glue_custom.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "glue_custom_attach" {
  role       = aws_iam_role.glue.name
  policy_arn = aws_iam_policy.glue_custom.arn
}

################################################################################
#  Secrets Manager (RDS creds)
################################################################################
resource "aws_secretsmanager_secret" "rds_creds" {
  name = "${var.project}-rds-creds"
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

################################################################################
#  RDS MySQL (terraform-aws-modules/rds)
################################################################################
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.0.0"

  identifier = "${var.project}-mysql"

  engine            = "mysql"
  engine_version    = "8.0.36"
  family            = "mysql8.0"
  instance_class    = "db.t3.small"
  allocated_storage = 20
  max_allocated_storage = 100

  username = "glue_admin"
  password = random_password.db_password.result

  multi_az               = true
  subnet_ids             = slice(module.vpc.private_subnets, 2, 4) # db subnets
  vpc_security_group_ids = [aws_security_group.rds.id]

  storage_encrypted       = true
  backup_retention_period = 7
  deletion_protection     = false

  tags = var.tags
}

################################################################################
# Glue catalog, connection, crawler, and ETL Job
################################################################################
resource "aws_glue_catalog_database" "raw" {
  name = "wex_raw"
}

resource "aws_glue_connection" "mysql" {
  name = "wex-mysql-conn"

  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:mysql://${module.rds.this_db_instance_address}:3306/${var.database_name}"
    SECRET_ID           = aws_secretsmanager_secret.rds_creds.id
  }

  physical_connection_requirements {
    subnet_id            = module.vpc.private_subnets[0]     # app subnet
    security_group_id_list = [aws_security_group.glue_jobs.id]
  }

  depends_on = [module.endpoints] # make sure Glue endpoint is ready
}

resource "aws_s3_object" "glue_script" {
  bucket  = aws_s3_bucket.data.id
  key     = "scripts/wex_transform.py"
  content = file("${path.module}/scripts/wex_transform.py")
  etag    = filemd5("${path.module}/scripts/wex_transform.py")
}

resource "aws_glue_job" "transform" {
  name     = "wex-transform"
  role_arn = aws_iam_role.glue.arn

  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 2
  timeout           = 2880 # 48 h safeguard

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${aws_s3_bucket.data.id}/${aws_s3_object.glue_script.key}"
  }

  connections = [aws_glue_connection.mysql.name]

  default_arguments = {
    "--job-language"                       = "python"
    "--TempDir"                            = "s3://${aws_s3_bucket.data.id}/temporary/"
    "--enable-continuous-cloudwatch-log"   = "true"
  }

  tags = var.tags
}

resource "aws_glue_crawler" "raw_csv" {
  name          = "wex-raw-csv"
  role          = aws_iam_role.glue.arn
  database_name = aws_glue_catalog_database.raw.name

  s3_target {
    path = "s3://${aws_s3_bucket.data.id}/raw/"
  }

  schema_change_policy {
    update_behavior = "LOG"
    delete_behavior = "DEPRECATE_IN_DATABASE"
  }

  tags = var.tags
}
