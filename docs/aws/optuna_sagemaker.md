# Documentation for Terraform Templates for Optuna with SageMaker

This repository contains Terraform templates and lifecycle scripts designed to set up an environment for running hyperparameter optimization (HPO) with Optuna on Amazon SageMaker. The templates and scripts are based on the [AWS blog post](https://aws.amazon.com/blogs/machine-learning/implementing-hyperparameter-optimization-with-optuna-on-amazon-sagemaker/) and the associated [GitHub repository](https://github.com/aws-samples/amazon-sagemaker-optuna-hpo-blog). Additionally, it incorporates lifecycle scripts for setting up `code-server` on SageMaker, adapted from the [AWS Code-Server solution](https://github.com/aws-samples/amazon-sagemaker-codeserver).

## Overview

```
├── backend.hcl-example            # Example configuration for Terraform backend
├── ecr.tf                         # Creates an Elastic Container Registry for Docker images
├── iam.tf                         # IAM roles and policies for SageMaker and related services
├── lifecycle_scripts              # Lifecycle scripts for installing and configuring code-server
│   ├── install_codeserver.sh      # Script to install code-server
│   └── setup_codeserver.sh        # Script to configure code-server during startup
├── main.tf                        # Main Terraform configuration file
├── outputs.tf                     # Outputs for the Terraform module
├── rds.tf                         # RDS configuration for databases
├── s3.tf                          # S3 bucket configuration for storage
├── sagemaker.tf                   # SageMaker configurations for running HPO
├── secrets_manager.tf             # Secrets Manager for handling sensitive information
├── security_groups.tf             # Security groups for network access
├── variables.tf                   # Variable definitions
├── variables.tfvars-example       # Example of variable values
└── vpc.tf                         # VPC configuration
```

## Lifecycle Script Descriptions

- **`install_codeserver.sh`**
    - Installs `code-server` during the creation of a new SageMaker Notebook Instance.
    - Executes only once during the initial setup.

- **`setup_codeserver.sh`**
    - Configures `code-server` every time the notebook instance starts, including the initial setup and subsequent restarts.
