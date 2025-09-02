# Backend variables
variable "region" {
  type        = string
  description = "AWS region where resources will be deployed"
}

variable "profile" {
  type        = string
  description = "AWS configuration profile with AdministratorAccess permissions"
}

variable "project_prefix" {
  type        = string
  description = "Prefix to use when naming all resources for the project"
}

# VPC variables
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

# Sagemaker
variable "sagemaker_instance_type" {
  description = "The instance type for the SageMaker notebook"
  type        = string
}

variable "sagemaker_default_ebs_volume_size_in_gb" {
  description = "The default size in GB of the EBS volume for SageMaker spaces"
  type        = number
}

variable "sagemaker_maximum_ebs_volume_size_in_gb" {
  description = "The maximum allowed size in GB of the EBS volume for SageMaker spaces"
  type        = number
}

# Git
variable "git_username" {
  description = "The username for the Git repository"
  type        = string
}

variable "git_pat" {
  description = "The personal access token for the Git repository"
  type        = string
}

# ECR and S3 variables
variable "s3_bucket" {
  type        = string
  description = "Name of the S3 bucket for storing scrapper data"
}

variable "retained_image_count" {
  description = "Number of images to retain with a specific tag"
  type        = number
}

variable "untagged_image_expiry_days" {
  description = "Number of days after which untagged images will expire"
  type        = number
}
