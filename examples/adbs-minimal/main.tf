locals {
  project = "your_project_id"
  customer_email = "your_email@here"
  location = "europe-west2" 
}

module "gcp-oci-adbs-quickstart" {
  # source = "github.com/oci-landing-zones/terraform-oci-multicloud-google//templates/gcp-oci-adbs-quickstart"
  source = "../../templates/gcp-oci-adbs-quickstart"
  
  project = local.project
  customer_email = local.customer_email
  location = local.location
  admin_password = var.admin_password

  network_name = "vpc-adbs-tutorial"
  cidr = "10.1.0.0/24"
  deletion_protection = false
}

