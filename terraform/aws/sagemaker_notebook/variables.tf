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

variable "public_subnet_cidrs" {
  description = "The CIDR blocks for public subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
}

# Sagemaker
variable "sagemaker_instance_type" {
  description = "The instance type for the SageMaker notebook"
  type        = string
}

variable "sagemaker_volume_size" {
  description = "The size of the EBS volume, in gigabytes, attached to the SageMaker instance"
  type        = number
}

# Git
variable "git_repo_url" {
  description = "The URL of the Git repository"
  type        = string
}

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
