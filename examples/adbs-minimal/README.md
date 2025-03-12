# Provision Autonomous Database @ Google Cloud with minimal inputs

This example provision a Autonomous Database @ Google Cloud by using the [gcp-oci-adbs-quickstart](#module\_gcp-oci-adbs-quickstart) template with minimal input.

## Example
[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2Foci-landing-zones%2Fterraform-oci-multicloud-google&cloudshell_git_branch=main&cloudshell_open_in_editor=main.tf&cloudshell_workspace=.%2Fexamples%2Fadbs-minimal&cloudshell_tutorial=..%2F..%2Fdocs%2Ftutorials%2Fadbs-terraform%2FREADME.md)

```tf
module "gcp-oci-adbs-quickstart" {
  # source = "github.com/oci-landing-zones/terraform-oci-multicloud-google//templates/gcp-oci-adbs-quickstart"
  source = "../../templates/gcp-oci-adbs-quickstart"
  project = "example"
  location = "europe-west2"  
  network_name = "example-vpc"
  cidr = "10.1.0.0/24"
  customer_email = "your_email@here"
  admin_password = "DoNotKeepThis$1234"
}

output "adbs_ocid" {
  description = "OCID of this Autonomous Database @ Google Cloud"
  value = module.gcp-oci-adbs-quickstart.oci_adbs_ocid
}
```

## Architecture
![gcp-oci-adbs-quickstart](../../images/gcp-oci-adbs-quickstart.png)
