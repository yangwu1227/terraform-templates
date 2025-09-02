# Optuna with SageMaker Studio

Sets up an environment for running hyperparameter optimization (HPO) with [Optuna](https://github.com/optuna/optuna) on Amazon SageMaker Studio.

The configuration files and scripts are adapted from an [AWS blog post](https://aws.amazon.com/blogs/machine-learning/implementing-hyperparameter-optimization-with-optuna-on-amazon-sagemaker/) and its associated [GitHub repository](https://github.com/aws-samples/amazon-sagemaker-optuna-hpo-blog).

Additionally, it incorporates lifecycle script for setting up `sagemaker-code-editor` in SageMaker Studio.

## Overview

<center>
<img src="../diagrams/optuna_sagemaker.png" alt="Optuna with SageMaker" width="80%"/>
</center>

```python
├── backend.hcl-example            # Example configuration for Terraform backend
├── ecr.tf                         # Creates an Elastic Container Registry for Docker images used for training, preprocessing, or serving
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

---

## Lifecycle Script

This lifecycle script shows examples for the following:

**Installation**

- Tools into the `base` conda environment
- Python dependency management tools `poetry`, `uv`, and `pdm`
- Extensions for `sagemaker-code-editor`

**Configuration**

- Configurations for `conda` and `git`
- Keyboard shortcuts and settings for `sagemaker-code-editor`

**References**

- [External library and kernel installation](https://docs.aws.amazon.com/sagemaker/latest/dg/nbi-add-external.html)
- [Create a lifecycle configuration to install Code Editor extensions](https://docs.aws.amazon.com/sagemaker/latest/dg/code-editor-use-lifecycle-configurations-extensions.html)
- [Code Editor in Amazon SageMaker Studio](https://docs.aws.amazon.com/sagemaker/latest/dg/code-editor.html)

---

## Modules

### 1. **`vpc.tf`**

**Provisioned Resources:**

- **VPC**: Defines a Virtual Private Cloud (VPC) for network isolation.
- **Subnets**: Creates public and private subnets for resource placement.
- **Internet Gateway**: Enables internet access for public subnets.
- **NAT Gateways**: Provides internet access for private subnets.
- **Route Tables**: Manages routing within the VPC for public and private subnets.

**Dependencies:**

- Other resources, such as RDS and SageMaker, rely on the VPC and its subnets for network configuration.
- Security groups (from `security_groups.tf`) are tied to this VPC.

---

### 2. **`security_groups.tf`**

**Provisioned Resources:**

- **SageMaker Security Group**: Allows outbound internet access for SageMaker Studio.

**Dependencies:**

- Used by resources in `sagemaker.tf` for network access control.

---

### 3. **`secrets_manager.tf`**

> Note: As of 2025, code repository integration is only supported for JupyterLab and JupyterServer apps, not the Code Editor in SageMaker Studio. Additionally, private repositories are not yet supported. Therefore, this secret remains unused in the current configuration. Repository must be cloned manually using this secret if needed.

**Provisioned Resources:**

- **Secrets**: Manages sensitive data such as:
  - GitHub Personal Access Token for SageMaker's code repository.
  - RDS credentials for database access.
- **Random String/Password**: Generates unique identifiers and secure passwords.

**Dependencies:**

- Secrets are referenced by the SageMaker code repository (`sagemaker.tf`) and RDS cluster (`rds.tf`).
- RDS uses the credentials stored in Secrets Manager for secure access.

---

### 4. **`sagemaker.tf`**

**Provisioned Resources:**

- **SageMaker Domain**: Creates the Studio domain with IAM authentication and public internet access.
- **User Profile**: Configures a named user profile with specific execution roles and security settings.
- **SageMaker Space**: Sets up a "private" space within the domain.
- **Lifecycle Configuration**: Defines a Code Editor lifecycle configuration using the setup script.

**Key Design:**

- Docker access is enabled for container development.
- Code Editor app settings with specified instance types.
- EBS storage configuration with default and maximum volume sizes.
- Auto-mounting of EFS home directories.`

**Dependencies:**

- Depends on IAM roles (`iam.tf`), public subnets (`vpc.tf`), security groups (`security_groups.tf`), and Secrets Manager secrets (`secrets_manager.tf`).

**References**

- [Amazon SageMaker AI domain overview](https://docs.aws.amazon.com/sagemaker/latest/dg/gs-studio-onboard.html)
- [Amazon SageMaker domain user profiles](https://docs.aws.amazon.com/sagemaker/latest/dg/domain-user-profile.html)
- [Connect your local Visual Studio Code to SageMaker spaces with remote access](https://docs.aws.amazon.com/sagemaker/latest/dg/remote-access.html)
- [Amazon SageMaker Studio spaces](https://docs.aws.amazon.com/sagemaker/latest/dg/studio-updated-spaces.html)
- [Amazon EFS auto-mounting in Studio](https://docs.aws.amazon.com/sagemaker/latest/dg/studio-updated-automount.html)

---

### 5. **`s3.tf`**

**Provisioned Resources:**

- **S3 Bucket**: Provides storage for datasets, artifacts, and outputs.

**Dependencies:**

- The IAM role (`iam.tf`) grants permissions to SageMaker Studio for accessing this bucket.

---

### 6. **`iam.tf`**

**Provisioned Resources:**

- **SageMaker Execution Role**: Creates an IAM role that SageMaker can assume to access AWS resources.
- **Custom IAM Policies**:
  - **S3 Policy**: Grants full access to the specified S3 bucket.
  - **Remote Access Policy**: Enables SageMaker [remote access](https://docs.aws.amazon.com/sagemaker/latest/dg/remote-access-remote-setup.html) feature.
- **Policy Attachments**: Attaches the following policies to the SageMaker execution role:
  - **S3 Policy**: Grants access to the S3 bucket created in `s3.tf` and the external S3 bucket used for Terraform [remote state](https://developer.hashicorp.com/terraform/language/state/remote)
  - **Remote Access Policy**: Grants `sagemaker:StartSession` permission to enable remote access to SageMaker Studio compute instances
  - `AmazonSageMakerFullAccess` (AWS managed policy)
  - `AmazonEC2ContainerRegistryFullAccess` (AWS managed policy)
  - `SecretsManagerReadWrite` (AWS managed policy)

**Dependencies:**

- SageMaker Studio user assumes this execution role to interact with S3, ECR, Secrets Manager, and other AWS services.
- The role is referenced in the SageMaker domain, user profiles, and for accessing S3 buckets.

---

### 7. **`ecr.tf`**

**Provisioned Resources:**

- **ECR Repository**: Creates an Elastic container registry repository for storing Docker images.
- **Lifecycle Policy**: Configures automatic cleanup of images with two rules:
  - Retains only the most recent images tagged as "latest"
  - Expires untagged images after a specified number of days

**Dependencies:**

- The IAM role in `iam.tf` grants SageMaker permission to pull images from this repository.
- Used to store custom training, processing, or inference images.

---

### 8. **`rds.tf`**

**Provisioned Resources:**

- **Subnet Group**: Defines subnets where RDS instances are deployed.
- **Parameter Groups**: Configures database engine settings.
- **RDS Cluster**: Creates a database cluster for storing HPO results.
- **RDS Instances**: Adds instances to the database cluster for handling workloads.

**Dependencies:**

- Depends on private subnets from `vpc.tf` for deployment.
- Uses Secrets Manager credentials (`secrets_manager.tf`) for database access.
- The security group (`security_groups.tf`) controls access between SageMaker and RDS.
