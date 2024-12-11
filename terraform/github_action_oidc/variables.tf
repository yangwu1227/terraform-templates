# Variables with default values
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

variable "create_github_oidc_provider" {
  description = "Boolean to decide whether to create the OIDC provider or use an existing one."
  type        = bool
}

variable "existing_oidc_provider_arn" {
  type        = string
  description = "Amazon Resource Name (ARN) of the GitHub OIDC provider for authentication"
}

variable "github_username" {
  type        = string
  description = "GitHub username for accessing the repository"
}

variable "github_repo_name" {
  type        = string
  description = "Name of the GitHub repository for this project"
}