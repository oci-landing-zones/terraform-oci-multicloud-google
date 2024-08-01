# Terraform Template to setup SSO Federation between OCI & GCP

Terraform module to fetch service provider metadata url and enable global access i.e. without authorization. This module performs the first step of the SSO configuration between OCI and Google.

## Providers

| Name                                                                  | Version |
| --------------------------------------------------------------------- | ------- |
| [OCI](https://registry.terraform.io/providers/oracle/oci/latest/docs) | n/a     |

## Inputs Variables

| VARIABLE                |                     DESCRIPTION                     | REQUIRED |          DEFAULT_VALUE |                       SAMPLE VALUE |
| :---------------------- | :-------------------------------------------------: | :------: |-----------------------:| ---------------------------------: |
| `config_file_profile`   |                OCI CLI profile name                 |   Yes    |                        |                       "ONBOARDING" |
| `compartment_ocid`      |                    Tenancy OCID                     |   Yes    |                        | "ocid1.tenancy.oc1..xxxxxxxxxxxxx" |
| `region`                |                OCI region Identifier                |   Yes    |                        |                     "us-ashburn-1" |
| `domain_display_name`   |              OCI Identify Domain Name               |    No    |              "Default" |                                    |

## Output Values

| VARIABLE                  |              DESCRIPTION              |                             SAMPLE VALUE                              |
|:--------------------------|:-------------------------------------:|:---------------------------------------------------------------------:|
| `domain_url`              |         Identity domains url          |          https://idcs-xxxxxxxxx.identity.pint.oracle.com:443          |
| `domain_metadata_xml_url` |   Identity domains metadata xml url   | https://idcs-xxxxxxxxx.identity.pint.oc9qadev.com:443/fed/v1/metadata |
| `provider_id`             |        Provider ID / Entity ID        |       https://idcs-xxxxxxxxx.identity.pint.oc9qadev.com:443/fed       |
| `acs_url`                 | ACS (Assertion consumer service) URL  |  https://idcs-xxxxxxxxx.identity.pint.oc9qadev.com:443/fed/v1/sp/sso  |
| `next_steps`              | Next steps after domain being enabled |                                                                       |

### Setting param value

The following input tfvars _must_ be set

Either as `terraform.tfvars` file in same directory

```
config_file_profile="<MY_PROFILE_NAME>"
compartment_ocid="<MY_OCI_TENANCY_ID>"
region="<MY_REGION_IDENTIFIER>"
```

Or running as command line parameter

```
terraform apply -var="config_file_profile=ONBOARDING"  -var='compartment_ocid=ocid1.tenancy.oc1..xxxxxxxxxxxxx' -var='region=us-ashburn-1'
```

### Authentication

```
# authenticate OCI cli
oci session authenticate --region=<region-identifier>
```

### Execution

Assuming authentication is successful, and parameters tfvars are in same directory.
Initialize Terraform from `templates/gcp-oci-sso-federation`

```
terraform init
```

Run Terraform Plan from `templates/gcp-oci-sso-federation` to check the resources that will be created

```
terraform plan
```

Run Terraform Apply from `templates/gcp-oci-sso-federation`

```
terraform apply
```

## Troubleshooting

### Known Issues:

NA