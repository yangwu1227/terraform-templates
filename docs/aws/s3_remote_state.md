# S3 Remote State

This Terraform module is inspired by [this Stack Overflow answer](https://stackoverflow.com/a/48362341/12923148) and sets up an **S3 bucket** and a **DynamoDB table** for managing Terraform remote state storage and locking. It facilitates secure, versioned, and collaborative Terraform state management.

1. **S3 Remote State Backend**

    - Stores the Terraform state securely in an S3 bucket.
    - Enables versioning to track state file changes over time.
    - Includes a `prevent_destroy` lifecycle rule to avoid accidental deletion.

2. **DynamoDB State Locking**

    - Prevents concurrent state updates with a DynamoDB table for locking.
    - Supports both `PAY_PER_REQUEST` and `PROVISIONED` [billing modes](https://aws.amazon.com/dynamodb/pricing/on-demand/), providing cost-efficiency and scalability.
