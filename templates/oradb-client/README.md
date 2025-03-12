# oradb-client
This is an add-on template for provision client subnet and Ubuntu VM with pre-installed SQLPlus client in a given VPC.

## Example
```tf
module "oradb-client" {
  # source = "github.com/oci-landing-zones/terraform-oci-multicloud-google//templates/oradb-client"
  source = "../../templates/oradb-client"
  project = local.project
  location = local.location
  network_name = module.gcp-oci-adbs-quickstart.network_name
  cidr = "10.2.0.0/24"
}

output "client_vm" {
  value = module.oradb-client.client_vm
}
```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.8.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.8.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.egress](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.ingress](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_instance.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_compute_subnetwork.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [random_shuffle.zone](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/shuffle) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [google_compute_zones.available](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cidr"></a> [cidr](#input\_cidr) | The subnet CIDR range for the client subnet | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | GCP region where Autonmous Database is hosted. | `string` | n/a | yes |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | The name of the VPC network used by the Autonomous Database | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | The ID of the project in which the resource belongs. If it is not provided, the provider project is used. | `string` | n/a | yes |
| <a name="input_random_suffix_length"></a> [random\_suffix\_length](#input\_random\_suffix\_length) | n/a | `number` | `3` | no |
| <a name="input_vm_image"></a> [vm\_image](#input\_vm\_image) | n/a | `string` | `"ubuntu-2004-focal-v20250130"` | no |
| <a name="input_vm_type"></a> [vm\_type](#input\_vm\_type) | Machine type of the client VM | `string` | `"e2-medium"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_client_vm"></a> [client\_vm](#output\_client\_vm) | Info of client VM |
<!-- END_TF_DOCS -->