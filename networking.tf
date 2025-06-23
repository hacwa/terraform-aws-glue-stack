module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  name = "${local.name_prefix}-vpc"
  cidr = var.vpc_cidr
  azs  = ["${var.aws_region}a", "${var.aws_region}b"]

  public_subnets = [
    "10.0.0.0/24", # app‑a
    "10.0.1.0/24"  # app‑b
  ]

  private_subnets = [
    "10.0.10.0/24", # future
    "10.0.11.0/24",
    "10.0.20.0/24", # db‑a
    "10.0.21.0/24"  # db‑b
  ]

  enable_nat_gateway      = true
  one_nat_gateway_per_az  = true
  single_nat_gateway      = false
  enable_dns_hostnames    = true
  enable_dns_support      = true
  map_public_ip_on_launch = true

  tags = var.tags
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.5.2"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service_type    = "Gateway"
      service         = "s3"
      route_table_ids = toset(module.vpc.private_route_table_ids)
      tags            = var.tags
    }

    glue = {
      service_type        = "Interface"
      service             = "glue"
      subnet_ids          = slice(module.vpc.private_subnets, 0, 2) # 1 per AZ
      security_group_ids  = [aws_security_group.sg_glue_jobs.id]
      private_dns_enabled = true
      tags                = var.tags
    }

    secretsmanager = {
      service_type        = "Interface"
      service             = "secretsmanager"
      subnet_ids          = slice(module.vpc.private_subnets, 0, 2) # 1 per AZ
      security_group_ids  = [aws_security_group.sg_glue_jobs.id]
      private_dns_enabled = true
      tags                = var.tags
    }
  }
}
