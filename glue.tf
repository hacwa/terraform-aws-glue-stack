#############################################
# GLUE — connection · crawler · job · script
#############################################
###############################################################################
# glue_connection_mysql.tf
# Glue JDBC connection that pulls creds from the rds_creds secret
###############################################################################


resource "aws_glue_crawler" "raw_csv" {
  name          = "${local.name_prefix}-raw-csv"
  role          = aws_iam_role.glue.arn
  database_name = "wex_raw"

  s3_target {
    # MUST be s3://  URI for provider ≥ 5.x
    path = "s3://${aws_s3_bucket.data.bucket}/raw/"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "DEPRECATE_IN_DATABASE"
  }

  tags = var.tags
}


#  Upload the ETL Python script to S3 (modern resource)

resource "aws_s3_object" "script" {
  bucket = aws_s3_bucket.data.id
  key    = "scripts/wex_transform.py"
  source = "${path.module}/scripts/wex_transform.py"
  etag   = filemd5("${path.module}/scripts/wex_transform.py")

  tags = var.tags
}

#
# Glue Spark job: read CSV → transform → write MySQL
#
resource "aws_glue_job" "transform" {
  name     = "${local.name_prefix}-transform"
  role_arn = aws_iam_role.glue.arn

  depends_on = [
    aws_glue_connection.mysql,
    aws_glue_connection.network,
    aws_s3_object.script
  ]


  glue_version      = "4.0" # Spark 3.4
  worker_type       = "G.1X"
  number_of_workers = var.glue_workers
  execution_property { max_concurrent_runs = 1 }

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${aws_s3_bucket.data.bucket}/${aws_s3_object.script.key}"
  }

  # JDBC connection created above
  connections = [
    aws_glue_connection.network.name, # add this line
    aws_glue_connection.mysql.name    # keep the JDBC connection
  ]


  default_arguments = {
    "--job-language"                     = "python"
    "--TempDir"                          = "s3://${aws_s3_bucket.data.bucket}/temporary/"
    "--s3_bucket"                        = aws_s3_bucket.data.bucket
    "--connection_name"                  = aws_glue_connection.mysql.name
    "--enable-continuous-cloudwatch-log" = "true"
  }

  tags = var.tags
}
