# SageMaker Studio

> As of 2025, the [project](https://github.com/aws-samples/amazon-sagemaker-codeserver) behind this set up is effectively archived (last release was 2023). For a more modern setup with more active AWS support, see the setup for [Sagemaker Studio](https://docs.aws.amazon.com/sagemaker/latest/dg/studio-updated.html).

This setup can be used for running a SageMaker Studio environment with a simple network infrastructure, minimal IAM and security configurations. The configuration files provide the essential components needed to deploy a VPC, S3 storage, ECR repository for docker images, and security for SageMaker Studio.

> For a setup that integrates `optuna` for hyperparameter optimization, refer to the [Optuna SageMaker](optuna_sagemaker.md) documentation.

```
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

## Lifecycle Script Descriptions

- **`setup_coder_editor.sh`**
  - Configures the code editor environment in SageMaker Studio.
  - Sets up necessary dependencies and preferences for development.

---

## Modules

### 1. **`vpc.tf`**

- **Provisioned Resources:**
  - **VPC**: Defines a Virtual Private Cloud (VPC) for network isolation with DNS support enabled.
  - **Public Subnets**: Dynamically creates public subnets across two availability zones.
  - **Internet Gateway**: Enables internet access for public subnets.
  - **Route Tables**: Configures routing for public subnets with default routes to the internet gateway.

- **Key Design:**
  - Uses dynamic subnet CIDR allocation based on the VPC CIDR block
  - Automatically selects availability zones with "opt-in-not-required" status
  - Configures public IP assignment for instances launched in public subnets
  - Creates consistent tagging across all networking

- **Dependencies:**
  - Provides networking for SageMaker Studio and other resources.
  - Security groups (from `security_groups.tf`) are tied to this VPC.

---

### 2. **`security_groups.tf`**

- **Provisioned Resources:**
  - **SageMaker Security Group**: Allows outbound internet access for SageMaker Studio.

- **Dependencies:**
  - Used by resources in `sagemaker.tf` for network access control.

---

### 3. **`secrets_manager.tf`**

As of 2025, code repository is only supported for JupyterLab and JupyterServer, not Code Editor. In addition, private repository is not supported. Therefore, this secret is not used in the current setup.

- **Provisioned Resources:**
  - **Secrets**: Manages sensitive data such as:
    - GitHub Personal Access Token for SageMaker's code repository.

---

### 4. **`sagemaker.tf`**

- **Provisioned Resources:**
  - **SageMaker Domain**: Creates the Studio domain environment with IAM authentication and public internet access.
  - **User Profile**: Configures a named user profile with specific execution roles and security settings.
  - **SageMaker Space**: Sets up a collaborative space within the domain.
  - **Lifecycle Configuration**: Defines a Code Editor lifecycle configuration using the setup script.

- **Key Design:**
  - Docker access is enabled for container development
  - Code Editor app settings with specified instance types
  - EBS storage configuration with default and maximum volume sizes
  - Auto-mounting of EFS home directories

- **Dependencies:**
  - Depends on IAM roles (`iam.tf`), public subnets (`vpc.tf`), security groups (`security_groups.tf`), and Secrets Manager secrets (`secrets_manager.tf`).

---

### 5. **`s3.tf`**

- **Provisioned Resources:**
  - **S3 Bucket**: Provides storage for datasets, artifacts, and outputs.

- **Dependencies:**
  - The IAM role (`iam.tf`) grants permissions to SageMaker Studio for accessing this bucket.

---

### 6. **`iam.tf`**

- **Provisioned Resources:**
  - **SageMaker Execution Role**: Creates an IAM role that SageMaker can assume to access AWS resources.
  - **Custom IAM Policies**:
    - **S3 Policy**: Grants full access to the specified S3 bucket.
    - **Remote Access Policy**: Enables SageMaker [remote access](https://docs.aws.amazon.com/sagemaker/latest/dg/remote-access-remote-setup.html) feature.
  - **Policy Attachments**: Attaches the following policies to the SageMaker execution role:
    - Custom S3 access policy
    - Custom remote access policy
    - `AmazonSageMakerFullAccess` (AWS managed policy)
    - `AmazonEC2ContainerRegistryFullAccess` (AWS managed policy)
    - `SecretsManagerReadWrite` (AWS managed policy)

- **Dependencies:**
  - SageMaker Studio uses this role to interact with S3, ECR, Secrets Manager, and other AWS services.
  - The role is referenced in the SageMaker domain, user profiles, and for accessing S3 buckets.

---

### 7. **`ecr.tf`**

- **Provisioned Resources:**
  - **ECR Repository**: Creates an Elastic Container Registry repository for storing Docker images.
  - **Lifecycle Policy**: Configures automatic cleanup of images with two rules:
    - Retains only the most recent images tagged as "latest"
    - Expires untagged images after a specified number of days

- **Dependencies:**
  - The IAM role in `iam.tf` grants SageMaker permission to pull images from this repository.
  - Used by SageMaker for custom training
