# Sagemaker domain
resource "aws_sagemaker_domain" "sagemaker_domain" {
  domain_name             = "${replace(var.project_prefix, "_", "-")}-domain"
  auth_mode               = "IAM"
  vpc_id                  = aws_vpc.main.id
  subnet_ids              = [aws_subnet.public["0"].id]
  app_network_access_type = "PublicInternetOnly"

  domain_settings {
    docker_settings {
      enable_docker_access = "ENABLED" # Inconsistent all caps
    }
    security_group_ids = [aws_security_group.sagemaker_sg.id]
  }

  default_space_settings {
    execution_role  = aws_iam_role.sagemaker_execution_role.arn
    security_groups = [aws_security_group.sagemaker_sg.id]
  }

  default_user_settings {
    auto_mount_home_efs = "Enabled" # Inconsistent title case
    execution_role      = aws_iam_role.sagemaker_execution_role.arn
    security_groups     = [aws_security_group.sagemaker_sg.id]

    code_editor_app_settings {
      default_resource_spec {
        instance_type        = var.sagemaker_instance_type
        lifecycle_config_arn = aws_sagemaker_studio_lifecycle_config.code_editor.arn
      }
      lifecycle_config_arns = [aws_sagemaker_studio_lifecycle_config.code_editor.arn]
    }
  }
  tags = {
    Name = "${var.project_prefix}_sagemaker_domain"
  }
}

# Sagemaker user profile for the domain
resource "aws_sagemaker_user_profile" "sagemaker_user_profile" {
  domain_id         = aws_sagemaker_domain.sagemaker_domain.id
  user_profile_name = "${replace(var.project_prefix, "_", "-")}-user"

  user_settings {
    execution_role  = aws_iam_role.sagemaker_execution_role.arn
    security_groups = [aws_security_group.sagemaker_sg.id]

    code_editor_app_settings {
      default_resource_spec {
        instance_type        = var.sagemaker_instance_type
        lifecycle_config_arn = aws_sagemaker_studio_lifecycle_config.code_editor.arn
      }
      lifecycle_config_arns = [aws_sagemaker_studio_lifecycle_config.code_editor.arn]
    }

    space_storage_settings {
      default_ebs_storage_settings {
        default_ebs_volume_size_in_gb = var.sagemaker_default_ebs_volume_size_in_gb
        maximum_ebs_volume_size_in_gb = var.sagemaker_maximum_ebs_volume_size_in_gb
      }
    }
  }

  tags = {
    Name = "${var.project_prefix}_sagemaker_user_profile"
  }
}

# Sagemaker space for the domain
resource "aws_sagemaker_space" "sagemaker_space" {
  domain_id  = aws_sagemaker_domain.sagemaker_domain.id
  space_name = "${replace(var.project_prefix, "_", "-")}-space"

  ownership_settings {
    owner_user_profile_name = aws_sagemaker_user_profile.sagemaker_user_profile.user_profile_name
  }

  space_sharing_settings {
    sharing_type = "Private"
  }

  space_settings {
    code_editor_app_settings {
      default_resource_spec {
        instance_type        = var.sagemaker_instance_type
        lifecycle_config_arn = aws_sagemaker_studio_lifecycle_config.code_editor.arn
      }
    }
  }

  tags = {
    Name = "${var.project_prefix}_sagemaker_space"
  }
}

# Lifecycle configuration for code editor
resource "aws_sagemaker_studio_lifecycle_config" "code_editor" {
  studio_lifecycle_config_name     = "${replace(var.project_prefix, "_", "-")}-setup-code-editor"
  studio_lifecycle_config_app_type = "CodeEditor"
  studio_lifecycle_config_content  = filebase64("${path.module}/lifecycle_scripts/setup_coder_editor.sh")

  tags = {
    Name = "${var.project_prefix}_code_editor_lifecycle_config"
  }
}
