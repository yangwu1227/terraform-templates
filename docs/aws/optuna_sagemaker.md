# Optuna with SageMaker

Sets up an environment for running hyperparameter optimization (HPO) with [Optuna](https://github.com/optuna/optuna) on Amazon SageMaker. The configuration files and scripts are adapted from an [AWS blog post](https://aws.amazon.com/blogs/machine-learning/implementing-hyperparameter-optimization-with-optuna-on-amazon-sagemaker/) and its associated [GitHub repository](https://github.com/aws-samples/amazon-sagemaker-optuna-hpo-blog). Additionally, it incorporates lifecycle scripts for setting up `code-server` on SageMaker, directly taken from the [AWS Code-Server solution](https://github.com/aws-samples/amazon-sagemaker-codeserver) developed by solutions engineers at AWS.

## Overview

<center>
<img src="../diagrams/optuna_sagemaker.png" alt="Optuna with SageMaker" width="80%"/>
</center>

```
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

## Lifecycle Script Descriptions

- **`install_codeserver.sh`**
    - Installs `code-server` during the creation of a new SageMaker Notebook Instance.
    - Executes only once during the initial setup.

- **`setup_codeserver.sh`**
    - Configures `code-server` every time the notebook instance starts, including the initial setup and subsequent restarts.

## Roles of `.tf` Files

1. **Core Network** (`vpc.tf`):
    - Serves as the backbone for all other resources (SageMaker, RDS, etc.).
2. **Security** (`security_groups.tf`):
    - Ensures proper access control between SageMaker, RDS, and external services.
3. **Sensitive Data** (`secrets_manager.tf`):
    - Secures credentials and secrets required by SageMaker and RDS.
4. **IAM** (`iam.tf`):
    - Permission sets for SageMaker to interact with S3, ECR, and Secrets Manager.
5. **RDS** (`rds.tf`):
    - Provides a database for storing HPO results, accessible from the SageMaker notebook.
6. **SageMaker** (`sagemaker.tf`):
    - Hosts the core notebook instance for running Optuna and managing HPO tasks.
7. **Storage** (`s3.tf`, `ecr.tf`):
    - Stores datasets, model artifacts, and container images required by training, preprocessing, and serving tasks.

### 1. **`vpc.tf`**
- **Provisioned Resources:**

    - **VPC**: Defines a Virtual Private Cloud (VPC) for network isolation.
    - **Subnets**: Creates public and private subnets for resource placement.
    - **Internet Gateway**: Enables internet access for public subnets.
    - **NAT Gateways**: Provides internet access for private subnets.
    - **Route Tables**: Manages routing within the VPC for public and private subnets.

- **Dependencies:**
    - Other resources, such as RDS and SageMaker, rely on the VPC and its subnets for network configuration.
    - Security groups (from `security_groups.tf`) are tied to this VPC.

---

### 2. **`security_groups.tf`**
- **Provisioned Resources:**
    - **SageMaker Security Group**: Allows outbound internet access for SageMaker notebook instances.
    - **RDS Security Group**: Allows inbound traffic to RDS from sageMaker only.

- **Dependencies:**
    - The SageMaker security group is used by resources in `sagemaker.tf`.
    - The RDS security group is associated with RDS resources in `rds.tf` and uses rules that reference the SageMaker security group.

---

### 3. **`secrets_manager.tf`**
- **Provisioned Resources:**
    - **Secrets**: Manages sensitive data such as:
        - GitHub Personal Access Token for SageMaker's code repository.
        - RDS credentials for database access.
    - **Random String/Password**: Generates unique identifiers and secure passwords.

- **Dependencies:**
    - Secrets are referenced by the SageMaker code repository (`sagemaker.tf`) and RDS cluster (`rds.tf`).
    - RDS uses the credentials stored in Secrets Manager for secure access.

---

### 4. **`sagemaker.tf`**
- **Provisioned Resources:**
    - **Lifecycle Configuration**: Manages custom scripts for installing and configuring `code-server`.
    - **Code Repository**: Links SageMaker to a private GitHub repository using credentials from Secrets Manager.
    - **Notebook Instance**: Provisions the SageMaker notebook for experimentation and HPO tasks.

- **Dependencies:**
    - Depends on IAM roles (`iam.tf`), subnets (`vpc.tf`), security groups (`security_groups.tf`), and Secrets Manager secrets (`secrets_manager.tf`).
    - Relies on lifecycle scripts for custom configuration.

---

### 5. **`s3.tf`**
- **Provisioned Resources:**
    - **S3 Bucket**: Provides storage for training artifacts and datasets.

- **Dependencies:**
    - SageMaker (`sagemaker.tf`) and other components can use this bucket for storing intermediate and final outputs.
    - The IAM role (`iam.tf`) grants permissions to the sagemaker role for accessing this bucket.

---

### 6. **`rds.tf`**
- **Provisioned Resources:**
    - **Subnet Group**: Defines subnets where RDS instances are deployed.
    - **Parameter Groups**: Configures database engine settings.
    - **RDS Cluster**: Creates a database cluster for storing HPO results.
    - **RDS Instances**: Adds instances to the database cluster for handling workloads.

- **Dependencies:**
    - Depends on private subnets from `vpc.tf` for deployment.
    - Uses Secrets Manager credentials (`secrets_manager.tf`) for database access.
    - The security group (`security_groups.tf`) controls access between SageMaker and RDS.

---

### 7. **`outputs.tf`**
- **Purpose:**
    - Exposes key details about the infrastructure, such as:
        - VPC and subnet IDs for networking.
        - Security group IDs for access control.
        - RDS connection details (endpoint, credentials, database name) for use in training jobs.

- **Dependencies:**
    - Outputs are consumed by downstream processes, such as training jobs or other modules that require connection details.

---

### 8. **`iam.tf`**
- **Provisioned Resources:**
    - **IAM Role for SageMaker**: Grants necessary permissions to SageMaker for accessing S3, ECR, and Secrets Manager.
    - **Policies**: Access control can be fine-tuned using policies.

- **Dependencies:**
    - SageMaker relies on this role to access resources defined in `s3.tf`, `secrets_manager.tf`, and `ecr.tf`.

---

### 9. **`ecr.tf`**
- **Provisioned Resources:**
    - **ECR Repository**: Stores Docker images for custom SageMaker training jobs.
    - **Lifecycle Policy**: Manages cleanup of old or untagged images to optimize storage.

- **Dependencies:**
    - SageMaker uses the ECR repository for custom container images in training jobs.
    - The IAM role (`iam.tf`) grants access to this repository.
