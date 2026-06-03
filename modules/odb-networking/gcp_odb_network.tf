# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  gcp_odb_networks_output = {
    for key, network in google_oracle_database_odb_network.these : key => {
      id             = network.id
      name           = network.name
      odb_network_id = network.odb_network_id
      location       = network.location
      project        = network.project
      state          = network.state
      entitlement_id = try(network.entitlement_id, null)
    }
  }
}

resource "google_oracle_database_odb_network" "these" {
  for_each = var.gcp_odb_networks_configuration

  odb_network_id = each.value.odb_network_id
  network        = each.value.network
  location       = each.value.location != null ? each.value.location : var.default_location
  project        = each.value.project_id != null ? each.value.project_id : var.default_project_id

  gcp_oracle_zone     = each.value.gcp_oracle_zone != null ? each.value.gcp_oracle_zone : var.default_gcp_oracle_zone
  labels              = merge(local.module_tag, local.default_labels, each.value.labels)
  deletion_protection = each.value.deletion_protection != null ? each.value.deletion_protection : var.default_deletion_protection

  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]

    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    ignore_changes = [
      labels,
    ]

    precondition {
      condition     = each.value.location != null || var.default_location != null
      error_message = "Each ODB network must set location or default_location."
    }
  }
}
