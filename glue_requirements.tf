###############################################################################
# Glue JDBC connection wired to the ARN pulled above
###############################################################################


resource "aws_glue_connection" "mysql" {
  name            = "wex-glue-mysql-conn"
  connection_type = "JDBC"

  physical_connection_requirements {
    subnet_id              = module.vpc.private_subnets[0]
    security_group_id_list = [aws_security_group.sg_glue_jobs.id]
  }

  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:mysql://${module.rds.db_instance_endpoint}/${var.db_name}"
    SECRET_ID           = local.rds_secret_arn
  }

  tags = var.tags
}





#########################################################
# Allow Glue to call ec2:DescribeRouteTables
#########################################################

resource "aws_iam_role_policy" "glue_ec2_route_read" {
  name = "${local.name_prefix}-glue-ec2-route-read"
  role = aws_iam_role.glue.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "ec2:DescribeRouteTables",
      Resource = "*"
    }]
  })
}



#########################################################
# Give the Glue role minimal EC2 read access
#########################################################

resource "aws_iam_role_policy" "glue_ec2_readonly" {
  name = "${local.name_prefix}-glue-ec2-read"
  role = aws_iam_role.glue.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "ec2:DescribeVpcEndpoints",
      Resource = "*"
    }]
  })
}



#########################################################
# Allow Glue to tag the ENIs it creates
#########################################################

resource "aws_iam_role_policy" "glue_ec2_tag" {
  name = "${local.name_prefix}-glue-ec2-createtags"
  role = aws_iam_role.glue.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "ec2:CreateTags",
      Resource = "*"
    }]
  })
}



resource "aws_glue_connection" "network" {
  name            = "wex-glue-network"
  connection_type = "NETWORK"

  physical_connection_requirements {
    subnet_id              = module.vpc.private_subnets[0]
    availability_zone      = "${var.aws_region}a"
    security_group_id_list = [aws_security_group.sg_glue_jobs.id]
  }

  tags = var.tags
}
