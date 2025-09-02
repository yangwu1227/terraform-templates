terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "admin"
}

resource "aws_sagemaker_domain" "example" {
  domain_name = "test-domain"
  auth_mode   = "IAM"
  vpc_id      = "vpc-01d3792f292635cba"
  subnet_ids  = ["subnet-06205b11fb0baa562"]

  default_user_settings {
    execution_role = "arn:aws:iam::722696965592:role/sagemaker-execution-role"
  }
}

resource "aws_sagemaker_user_profile" "example" {
  domain_id         = aws_sagemaker_domain.example.id
  user_profile_name = "example-user"
}
