# GitHub Action OIDC

This module configures an OpenID Connect (OIDC) provider for GitHub Actions on AWS. It enables GitHub Actions to authenticate with AWS using OIDC tokens, enhancing security by removing the need for long-lived AWS credentials.

### Benefits of Using OIDC with GitHub Actions

Implementing OIDC with GitHub Actions offers a secure method for authenticating workflows with AWS. It minimizes the risk of credential exposure and simplifies secret management. For additional details, refer to the following resources:

- [Configuring OpenID Connect in Amazon Web Services](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [GitHub Actions: Update on OIDC integration with AWS](https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/)

### Example Github Action Workflow

```yaml
name: Example OIDC Workflow

on:
  pull_request:
    branches:
      - main

permissions:
  id-token: write  # Required for requesting the Json Web Token (JWT)
  contents: read   # Required for actions/checkout

jobs:
  example-job:
    name: Example Job
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        id: checkout-repo
        uses: actions/checkout@v4

      - name: Configure AWS credentials from OIDC
        id: configure-aws-credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          audience: sts.amazonaws.com
          aws-region: ${{ secrets.AWS_REGION }}  # Set the AWS region as a repository secret
          role-to-assume: ${{ secrets.AWS_GITHUB_ACTIONS_ROLE_ARN }}  # Set the role ARN as a repository secret
          role-session-name: example-session

      - name: Add profile credentials to ~/.aws/credentials
        id: add-profile-credentials
        run: |
          aws configure set aws_access_key_id ${{ env.AWS_ACCESS_KEY_ID }} --profile example_profile
          aws configure set aws_secret_access_key ${{ env.AWS_SECRET_ACCESS_KEY }} --profile example_profile
          aws configure set aws_session_token ${{ env.AWS_SESSION_TOKEN }} --profile example_profile
```
