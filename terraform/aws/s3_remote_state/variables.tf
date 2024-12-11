# Variables with default values
variable "region" {
  type        = string
  description = "AWS region where resources will be deployed"
}

variable "profile" {
  type        = string
  description = "AWS configuration profile with all required permissions"
}

variable "s3_remote_state_bucket" {
  type        = string
  description = "Name of the S3 bucket to use as backend for Terraform remote state"
}

variable "dynamodb_table_name" {
  type        = string
  description = "Name of the DynamoDB table to use as lock for Terraform remote state"
}

variable "dynamodb_table_billing_mode" {
  type        = string
  description = "DynamoDB table billing mode"
  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.dynamodb_table_billing_mode)
    error_message = "Billing mode must be one of PAY_PER_REQUEST or PROVISIONED"
  }
}

variable "dynamodb_table_hash_key" {
  type        = string
  description = "DynamoDB table hash key"
}

variable "dynamodb_table_read_capacity" {
  type        = number
  description = "DynamoDB table read capacity, required if billing mode is PROVISIONED"
  default     = null
}

variable "dynamodb_table_write_capacity" {
  type        = number
  description = "DynamoDB table write capacity, required if billing mode is PROVISIONED"
  default     = null
}
