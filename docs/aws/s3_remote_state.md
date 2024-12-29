# S3 Remote State

This module is based the following [Stack Overflow answer](https://stackoverflow.com/a/48362341/12923148) and sets up an **S3 bucket** and a **DynamoDB table** for managing Terraform remote state storage and locking.

In collaborative projects, storing the Terraform state file locally can lead to conflicts, inconsistencies, and even data loss. A remote backend, such as an S3 bucket, provides a centralized location for the state file.

While this module does not fully resolve the "chicken-and-egg" problem of initial state management— since a local state file is still used for this initial setup— it provides a simple and effective way to create an S3 bucket for storing state files for all subsequent resources. This approach minimizes project complexity while enabling the use of remote state management.

1. **S3 Remote State Backend**

    - Stores the Terraform state securely in an S3 bucket.
    - Enables versioning to track state file changes over time.
    - Includes a `prevent_destroy` lifecycle rule to avoid accidental deletion.

2. **DynamoDB State Locking**

    - Prevents concurrent state updates with a DynamoDB table for locking.
    - Supports both `PAY_PER_REQUEST` and `PROVISIONED` [billing modes](https://aws.amazon.com/dynamodb/pricing/on-demand/), which can be controlled using the `dynamodb_table_billing_mode` variable.
