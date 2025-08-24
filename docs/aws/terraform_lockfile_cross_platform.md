# Terraform Lock File Cross-Platform Issues

## Problem

When running Terraform workflows in CI/CD (e.g., GitHub Actions on Linux) after committing a `.terraform.lock.hcl` file generated locally on a different platform, e.g., macOS (Apple Silicon), validation using `terraform validate` may fail with an error like:

```txt
Error: registry.terraform.io/hashicorp/aws: the cached package for registry.terraform.io/hashicorp/aws 6.10.0 (in .terraform/providers) does not match any of the checksums recorded in the dependency lock file
```

This happens when the lock file only contains provider checksums for the local platform (e.g., `darwin_arm64`), but the CI runner requires Linux builds.

## Explanation

- Terraform lock files (`.terraform.lock.hcl`) store **checksums of provider binaries per platform**.

- By default, `terraform init` records checksums for the current system only.

- If we generate the lock file on macOS (`darwin_arm64`) and commit it, a Linux runner (`linux_amd64`) will download different provider binaries. Since the lock file lacks Linux checksums, Terraform refuses to proceed with `validate` or `plan` under `terraform init -lockfile=readonly`.

- If we ran `terraform init` **without** `-lockfile=readonly`, Terraform would silently re-lock based on the runner’s platform, masking the mismatch.

## How to Avoid

1. **Generate multi-platform lock files** before committing:

   ```bash
   terraform providers lock -platform=linux_amd64 -platform=linux_arm64 -platform=darwin_amd64 -platform=darwin_arm64
   ```

   This ensures the lock file contains checksums for both macOS and Linux runners.

2. **Commit the updated `.terraform.lock.hcl`** to the remote repository.

3. **In CI/CD pipelines:**

   - Use `terraform init -lockfile=readonly` to enforce reproducibility.
   - Only use `terraform init -upgrade` when intentionally bumping provider versions.

By following these steps, Terraform will validate and run consistently across both local and CI environments without checksum mismatches.
