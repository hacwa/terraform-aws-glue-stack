############################
# General
############################
variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-1"
}

variable "project" {
  description = "Tag / resource name prefix"
  type        = string
  default     = ""
}

variable "owner" {
  description = "Tag 'Owner' applied to all resources"
  type        = string
  default     = "data-team"
}

############################
# VPC
############################
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

############################
# RDS
############################
variable "db_username" {
  description = "Master username for MySQL"
  type        = string
  default     = "glue_admin"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "wexdb"
}

variable "db_instance_type" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small"
}

############################
# Glue
############################
variable "glue_workers" {
  description = "Number of Glue G.1X workers"
  type        = number
  default     = 2
}


variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)

  default = {
    Project = "wex"
    Owner   = "data-team"
  }
}
