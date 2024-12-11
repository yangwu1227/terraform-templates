provider "aws" {
  region  = var.region
  profile = var.profile
}

resource "aws_s3_bucket" "s3_remote_state" {
  bucket = var.s3_remote_state_bucket
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "s3_remote_state_versioning" {
  bucket = aws_s3_bucket.s3_remote_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "s3_remote_state_lock" {
  name           = var.dynamodb_table_name
  billing_mode   = var.dynamodb_table_billing_mode
  hash_key       = var.dynamodb_table_hash_key
  read_capacity  = var.dynamodb_table_billing_mode == "PROVISIONED" ? var.dynamodb_table_read_capacity : null
  write_capacity = var.dynamodb_table_billing_mode == "PROVISIONED" ? var.dynamodb_table_write_capacity : null
  attribute {
    name = "LockID"
    type = "S"
  }
}
