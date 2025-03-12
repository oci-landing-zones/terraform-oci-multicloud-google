# OCI Multicloud Landing Zone for Google Cloud

![Landing Zone logo](./images/landing_zone_300.png)

## Overview

A repository contains a collection of [terraform modules](https://developer.hashicorp.com/terraform/language/modules) and templates that helps an Google Cloud administrator configure an Google Cloud environment for Oracle Database@Google and provision database related components in Google Cloud.

A user can apply the terraform plans from any computer that has connectivity to both Google Cloud and OCI.

## Prerequisites

To use the Terraform modules and templates in your environment, you must install the following software on the system from which you execute the terraform plans:

- [Terraform](https://developer.hashicorp.com/terraform/install) or [OpenTofu](https://opentofu.org/docs/intro/)
- [Google Cloud CLI](https://cloud.google.com/sdk/docs/install)
- [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)
- [Google Cloud terraform provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [OCI terraform provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)

## Templates 
These module automates the provisioning of components for running Oracle Database@Google. Each template can run independently and default input values are configured which can be overridden per customer's preferences.
- [Quickstart for Autonomous Database](./templates/gcp-oci-adbs-quickstart/README.md)

## Tutorial
- [Provision Autonomous Database@Google Cloud with Terraform](https://shell.cloud.google.com/cloudshell/editor?&ephemeral=false&cloudshell_git_repo=https%3A%2F%2Fgithub.com%2Foci-landing-zones%2Fterraform-oci-multicloud-google&cloudshell_git_branch=main&cloudshell_open_in_editor=.%2Fexamples%2Fadbs-minimal%2Fmain.tf&cloudshell_workspace=.&cloudshell_tutorial=.%2Fdocs%2Ftutorials%2Fadbs-terraform%2FREADME.md)
- [Provision RAG Chatbot with Autonomous Database@Google Cloud](./docs/tutorials/adbs-rag-chatbot/README.md)

## Further Documentation

### Terraform Provider
- [Oracle Cloud Infrastructure Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [Google Cloud](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

### Terraform Modules
- [OCI Landing Zones](https://github.com/oci-landing-zones/)

**Acknowledgement:** Code derived adapted from samples, examples and documentations provided by above mentioned providers.

## Help

Open an [issue](https://github.com/oci-landing-zones/terraform-oci-multicloud-google/issues) in this repository.

## Contributing

This project welcomes contributions from the community. Before submitting a pull request, please [review our contribution guide](./CONTRIBUTING.md).

## Security

Please consult the [security guide](./SECURITY.md) for our responsible security vulnerability disclosure process.

## License

Copyright (c) 2025 Oracle and/or its affiliates.

Released under the Universal Permissive License v1.0 as shown at <https://oss.oracle.com/licenses/upl/>.