# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

module "odb_networking" {
  source = "../.."

  module_name                 = var.module_name
  enable_output               = var.enable_output
  default_project_id          = var.project_id
  default_location            = var.location
  default_gcp_oracle_zone     = var.gcp_oracle_zone
  default_deletion_protection = var.default_deletion_protection
  default_labels              = var.default_labels

  gcp_odb_networks_configuration = var.gcp_odb_networks_configuration
  gcp_odb_subnets_configuration  = var.gcp_odb_subnets_configuration
}
