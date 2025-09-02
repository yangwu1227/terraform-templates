# SageMaker Studio

> As of 2025, the [project](https://github.com/aws-samples/amazon-sagemaker-codeserver) behind setting up [code-server](https://github.com/coder/code-server) is effectively archived (last release was 2023). For a more modern setup with active development, see the setup for [Sagemaker Studio](https://docs.aws.amazon.com/sagemaker/latest/dg/studio-updated.html).

This setup can be used for running SageMaker Studio with a simple network infrastructure, security configurations, and minimal IAM. The configuration files provide the essential components needed to deploy a VPC, core Sagemaker resources (e.g., domain, user profile, space, lifecycle configuration), S3 for storage, and ECR repository for docker images.

> For a setup that integrates `optuna` for hyperparameter optimization, refer to the [Optuna SageMaker Studio](optuna_sagemaker_studio.md) documentation.

```python
├── backend.hcl-example            # Example configuration for Terraform backend
├── ecr.tf                         # Elastic Container Registry for custom Docker images
├── iam.tf                         # IAM roles and policies for SageMaker Studio
├── lifecycle_scripts              # Lifecycle scripts for configuring SageMaker Studio
│   └── setup_coder_editor.sh      # Script to configure the code editor environment
├── main.tf                        # Main Terraform configuration file
├── s3.tf                          # S3 bucket configuration
├── sagemaker.tf                   # SageMaker Studio configurations
├── secrets_manager.tf             # Secrets Manager for sensitive information
├── security_groups.tf             # Security groups for SageMaker Studio
├── variables.tf                   # Variable definitions
├── variables.tfvars-example       # Example variable values
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

- **VPC**: Defines a Virtual Private Cloud (VPC) for network isolation with DNS support enabled.
- **Public Subnets**: Dynamically creates public subnets across two availability zones.
- **Internet Gateway**: Enables internet access for public subnets.
- **Route Tables**: Configures routing for public subnets with default routes to the internet gateway.

**Key Design:**

- Uses dynamic subnet CIDR allocation based on the VPC CIDR block.
- Automatically selects availability zones with "opt-in-not-required" status.

**Dependencies:**

- Provides networking for SageMaker Studio and other resources.
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

- **Secrets**: GitHub Personal Access Token for GitHub repository.

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
- Auto-mounting of EFS home directories.

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
