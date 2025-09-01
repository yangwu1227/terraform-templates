# SageMaker Notebook

> As of 2025, the [project](https://github.com/aws-samples/amazon-sagemaker-codeserver) behind this set up is effectively archived (last release was 2023). For a more modern setup with more active AWS support, see the setup for [Sagemaker Studio](https://docs.aws.amazon.com/sagemaker/latest/dg/studio-updated.html).

This setup can be used for running a SageMaker notebook instance with a simple network infrastructure, minimal IAM and security configurations, and lifecycle scripts for setting up `code-server`. The configuration files provide the essential components needed to deploy a VPC, S3 storage, and security for SageMaker.

> For a setup that integrates `optuna` for hyperparameter optimization, refer to the [Optuna SageMaker](optuna_sagemaker.md) documentation.

```
├── backend.hcl-example            # Example configuration for Terraform backend
├── ecr.tf                         # Elastic Container Registry for custom Docker images
├── iam.tf                         # IAM roles and policies for SageMaker
├── lifecycle_scripts              # Lifecycle scripts for installing and configuring code-server
│   ├── install_codeserver.sh      # Script to install code-server
│   └── setup_codeserver.sh        # Script to configure code-server during startup
├── main.tf                        # Main Terraform configuration file
├── s3.tf                          # S3 bucket configuration
├── sagemaker.tf                   # SageMaker configurations
├── secrets_manager.tf             # Secrets Manager for sensitive information
├── security_groups.tf             # Security groups for SageMaker
├── variables.tf                   # Variable definitions
├── variables.tfvars-example       # Example variable values
└── vpc.tf                         # VPC configuration
```

---

## Lifecycle Script Descriptions

- **`install_codeserver.sh`**
    - Installs `code-server` during the creation of a new SageMaker Notebook Instance.
    - Executes only once during the initial setup.

- **`setup_codeserver.sh`**
    - Configures `code-server` every time the notebook instance starts, including the initial setup and subsequent restarts.

---

## Roles of `.tf` Files

### 1. **`vpc.tf`**

- **Provisioned Resources:**
    - **VPC**: Defines a Virtual Private Cloud (VPC) for network isolation.
    - **Public Subnets**: Creates two public subnets for resource placement.
    - **Internet Gateway**: Enables internet access for public subnets.
    - **Route Tables**: Manages routing for public subnets with internet access.

- **Dependencies:**
    - Provides networking for SageMaker and other resources.
    - Security groups (from `security_groups.tf`) are tied to this VPC.

---

### 2. **`security_groups.tf`**

- **Provisioned Resources:**
    - **SageMaker Security Group**: Allows outbound internet access for SageMaker notebook instances.

- **Dependencies:**
    - Used by resources in `sagemaker.tf` for network access control.

---

### 3. **`secrets_manager.tf`**

- **Provisioned Resources:**
    - **Secrets**: Manages sensitive data such as:
        - GitHub Personal Access Token for SageMaker's code repository.

- **Dependencies:**
    - Secrets are referenced by the SageMaker code repository (`sagemaker.tf`).

---

### 4. **`sagemaker.tf`**

- **Provisioned Resources:**
    - **Lifecycle Configuration**: Manages custom scripts for installing and configuring `code-server`.
    - **Code Repository**: Links SageMaker to a private GitHub repository using credentials from Secrets Manager.
    - **Notebook Instance**: Provisions the SageMaker notebook for experimentation and development tasks.

- **Dependencies:**
    - Depends on IAM roles (`iam.tf`), public subnets (`vpc.tf`), security groups (`security_groups.tf`), and Secrets Manager secrets (`secrets_manager.tf`).
    - Relies on lifecycle scripts for custom configuration.

---

### 5. **`s3.tf`**

- **Provisioned Resources:**
    - **S3 Bucket**: Provides storage for datasets, artifacts, and outputs.

- **Dependencies:**
    - The IAM role (`iam.tf`) grants permissions to SageMaker for accessing this bucket.

---

### 6. **`iam.tf`**

- **Provisioned Resources:**
    - **IAM Role for SageMaker**: Grants necessary permissions to SageMaker for accessing S3 and Secrets Manager.
    - **Policies**: Fine-tuned access control for SageMaker.

- **Dependencies:**
    - SageMaker relies on this role to interact with S3 and Secrets Manager.

---

### 7. **`ecr.tf`**

- **Provisioned Resources:**
    - **ECR Repository**: Stores Docker images for custom SageMaker training jobs.
    - **Lifecycle Policy**: Manages cleanup of old or untagged images to optimize storage.

- **Dependencies:**
    - SageMaker uses the ECR repository for custom container images in training jobs.
    - The IAM role (`iam.tf`) grants access to this repository.

