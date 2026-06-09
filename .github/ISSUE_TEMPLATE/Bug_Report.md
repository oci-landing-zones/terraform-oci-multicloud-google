---
name: Bug Report
about: Report a reproducible problem with the Oracle Database@Google Cloud Terraform modules
labels: bug
---

### Community Note

* Please vote on this issue by adding a reaction to the original issue to help the community and maintainers prioritize this request.
* Please do not leave "+1" or "me too" comments, as they generate extra noise for issue followers.
* If you are interested in working on this issue or have submitted a pull request, please leave a comment.

### Terraform, OpenTofu, and Provider Versions

<!--
Run `terraform version` or `tofu version` from the failing working directory.
Include the Google provider version and, if relevant, the OCI provider version.
-->

### Affected Module or Example

<!--
Examples:
- modules/odb-networking
- modules/adb
- modules/exadb
- modules/exadb/examples/cluster
-->

### Terraform Configuration

```hcl
# Paste the smallest configuration that reproduces the issue.
# Remove project IDs, OCIDs, passwords, keys, tokens, and other sensitive values.
```

### Expected Behavior

<!-- What should have happened? -->

### Actual Behavior

<!-- What actually happened? Include the relevant error message. -->

### Steps to Reproduce

1. `terraform init`
2. `terraform plan`

### Debug Output

<!--
If debug logs are needed, provide a link to a GitHub Gist.
Do not paste long debug output directly in the issue.
Remove sensitive values before sharing.
-->

### Environment Notes

<!--
Include anything specific to your environment, such as Google Cloud region,
Oracle Database@Google Cloud entitlement state, Shared VPC usage, or whether
the deployment uses direct resource names or dependency maps.
-->

### References

<!-- Link related issues, pull requests, provider docs, or Oracle documentation. -->
