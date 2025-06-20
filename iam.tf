

data "aws_caller_identity" "current" {}


resource "aws_iam_role" "glue" {
  name = "${local.name_prefix}-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "glue.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}



resource "aws_iam_role_policy" "glue_policy" {
  name = "${local.name_prefix}-glue-policy"
  role = aws_iam_role.glue.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      # ───── S3 (raw + scripts) ─────
      {
        Sid    = "S3ReadWrite",
        Effect = "Allow",
        Action = ["s3:GetObject", "s3:PutObject"],
        Resource = [
          aws_s3_bucket.data.arn,
          "${aws_s3_bucket.data.arn}/*"
        ]
      },
      {
        Sid      = "S3List",
        Effect   = "Allow",
        Action   = "s3:ListBucket",
        Resource = aws_s3_bucket.data.arn
      },

      # ───── CloudWatch Logs ─────
      {
        Sid      = "CWLogs",
        Effect   = "Allow",
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "arn:aws:logs:*:*:*"
      },

      # ───── EC2 ENI operations ─────
      {
        Sid    = "EC2ForGlueENI",
        Effect = "Allow",
        Action = [
          "ec2:DescribeSubnets", "ec2:DescribeSecurityGroups",
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface", "ec2:CreateNetworkInterfacePermission",
          "ec2:DeleteNetworkInterface"
        ],
        Resource = "*"
      },

      # ───── Glue Catalog & Connection objects ─────
      {
        Sid    = "GlueCatalogRead",
        Effect = "Allow",
        Action = ["glue:GetConnection", "glue:GetConnections"],
        Resource = [
          # the catalog
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:catalog",
          # every connection in the account (use “*” or list exact names)
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:connection/*"
        ]
      },

      # ───── Secrets Manager – AWS-managed RDS secret ─────
      {
        Sid      = "ReadRdsSecret",
        Effect   = "Allow",
        Action   = "secretsmanager:GetSecretValue",
        Resource = local.rds_secret_arn
      }
    ]
  })
}

#############################
# Output
#############################

output "glue_role_arn" {
  description = "IAM role assumed by Glue jobs"
  value       = aws_iam_role.glue.arn
}
