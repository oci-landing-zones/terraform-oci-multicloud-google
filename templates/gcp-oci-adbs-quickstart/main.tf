provider "google" {
  project = var.project
  region  = var.location
  default_labels = {
    tf-module = "gcp-oci-adbs-quickstart"
    tf-source = "terraform-oci-multicloud-google"
  }
}

locals {
  adbs_id   = "${var.adb_name}-${random_string.suffix.result}"
  adbs_name = "${var.adb_name}${random_string.suffix.result}"
  network_name = "${var.network_name}-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = var.random_suffix_length
  special = false
  upper   = false
  numeric = true
}

resource "google_compute_network" "this" {
  name = local.network_name
  project = var.project
  auto_create_subnetworks = false
}

# Oracle Autonomous Database
module "google_ora_adbs" {
  source = "../../modules/gcp-ora-adbs"
  depends_on = [ google_compute_network.this ]

  # Required
  location               = var.location
  autonomous_database_id = local.adbs_id
  database               = local.adbs_name
  network_name           = local.network_name
  cidr                   = var.cidr
  customer_email         = var.customer_email
  admin_password         = var.admin_password

  # Optional
  project                         = var.project
  display_name                    = var.display_name
  labels                          = var.labels
  compute_count                   = var.compute_count
  data_storage_size_tb            = var.data_storage_size_tb
  db_version                      = var.db_version
  db_edition                      = var.db_edition
  db_workload                     = var.db_workload
  is_auto_scaling_enabled         = var.is_auto_scaling_enabled
  license_type                    = var.license_type
  backup_retention_period_days    = var.backup_retention_period_days
  character_set                   = var.character_set
  is_storage_auto_scaling_enabled = var.is_storage_auto_scaling_enabled
  maintenance_schedule_type       = var.maintenance_schedule_type
  mtls_connection_required        = var.mtls_connection_required
  n_character_set                 = var.n_character_set
  operations_insights_state       = var.operations_insights_state
  private_endpoint_ip             = var.private_endpoint_ip
  private_endpoint_label          = var.private_endpoint_label
  deletion_protection             = var.deletion_protection
}
