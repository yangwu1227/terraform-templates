# GitHub Action OIDC

This module configures an OpenID Connect (OIDC) provider for GitHub Actions on AWS. It enables GitHub Actions to authenticate with AWS using OIDC tokens, enhancing security by removing the need for long-lived AWS credentials.

## Benefits of Using OIDC with GitHub Actions

Implementing OIDC with GitHub Actions offers a secure method for authenticating workflows with AWS. It minimizes the risk of credential exposure and simplifies secret management. For additional details, refer to the following resources:

- [Configuring OpenID Connect in Amazon Web Services](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [GitHub Actions: Update on OIDC integration with AWS](https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/)
