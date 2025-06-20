# SG for Glue workers
resource "aws_security_group" "sg_glue_jobs" {
  name        = "${local.name_prefix}-glue-jobs"
  description = "Outbound access for Glue"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG for MySQL
resource "aws_security_group" "sg_rds_mysql" {
  name        = "${local.name_prefix}-rds-mysql"
  description = "Allow Glue to reach RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Glue TCP 3306"
    protocol        = "tcp"
    from_port       = 3306
    to_port         = 3306
    security_groups = [aws_security_group.sg_glue_jobs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "glue_self_ingress" {
  description       = "Glue intra-node communication"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.sg_glue_jobs.id
  self              = true
}



resource "aws_security_group_rule" "allow_personal_ip_mysql" {
  description       = "Allow My IP to connect to MySQL"
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["185.137.223.79/32"]
  security_group_id = aws_security_group.sg_rds_mysql.id
}
