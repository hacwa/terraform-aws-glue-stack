

#  Bucket
resource "aws_s3_bucket" "data" {
  bucket        = "${local.name_prefix}-bucket"
  force_destroy = true
  tags          = var.tags
}

#  Versioning
resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id

  versioning_configuration {
    status = "Enabled"
  }
}

#  Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#  Lifecycle rule (30-day cleanup of /transformed/)
resource "aws_s3_bucket_lifecycle_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    id     = "temp-files"
    status = "Enabled"

    filter { prefix = "transformed/" }

    expiration { days = 30 }
  }
}
