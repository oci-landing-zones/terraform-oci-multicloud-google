# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  odb_network_resource_name_pattern = "^projects/[^/[:space:]]+/locations/[^/[:space:]]+/odbNetworks/[a-z]([a-z0-9-]{0,61}[a-z0-9])?$"

  odb_network_id_segments = {
    for key, network in var.gcp_odb_networks_configuration : key =>
    network.odb_network_id
  }

  odb_network_project_ids = {
    for key, network in var.gcp_odb_networks_configuration : key =>
    network.project_id != null ? network.project_id : var.default_project_id
  }

  odb_network_locations = {
    for key, network in var.gcp_odb_networks_configuration : key =>
    network.location != null ? network.location : var.default_location
  }

  odb_subnet_uses_local_odb_network = {
    for key, subnet in var.gcp_odb_subnets_configuration : key =>
    !can(regex("^projects/", subnet.odb_network)) && contains(keys(var.gcp_odb_networks_configuration), subnet.odb_network)
  }

  odb_subnet_uses_external_odb_network = {
    for key, subnet in var.gcp_odb_subnets_configuration : key =>
    can(regex(local.odb_network_resource_name_pattern, subnet.odb_network))
  }

  odb_subnet_external_odb_network_project_ids = {
    for key, subnet in var.gcp_odb_subnets_configuration : key =>
    local.odb_subnet_uses_external_odb_network[key] ? try(split("/", subnet.odb_network)[1], null) : null
  }

  odb_subnet_external_odb_network_locations = {
    for key, subnet in var.gcp_odb_subnets_configuration : key =>
    local.odb_subnet_uses_external_odb_network[key] ? try(split("/", subnet.odb_network)[3], null) : null
  }

  odb_subnet_external_odb_network_id_segments = {
    for key, subnet in var.gcp_odb_subnets_configuration : key =>
    local.odb_subnet_uses_external_odb_network[key] ? try(split("/", subnet.odb_network)[5], null) : null
  }

  odb_subnet_project_ids = {
    for key, subnet in var.gcp_odb_subnets_configuration : key =>
    subnet.project_id != null ? subnet.project_id : (
      var.default_project_id != null ? var.default_project_id : (
        local.odb_subnet_uses_local_odb_network[key] ? try(local.odb_network_project_ids[subnet.odb_network], null) : (
          local.odb_subnet_uses_external_odb_network[key] ? local.odb_subnet_external_odb_network_project_ids[key] : null
        )
      )
    )
  }

  odb_subnet_locations = {
    for key, subnet in var.gcp_odb_subnets_configuration : key =>
    subnet.location != null ? subnet.location : (
      var.default_location != null ? var.default_location : (
        local.odb_subnet_uses_local_odb_network[key] ? try(local.odb_network_locations[subnet.odb_network], null) : (
          local.odb_subnet_uses_external_odb_network[key] ? local.odb_subnet_external_odb_network_locations[key] : null
        )
      )
    )
  }

  gcp_odb_subnets_output = {
    for key, subnet in google_oracle_database_odb_subnet.these : key => {
      id            = subnet.id
      name          = subnet.name
      odb_subnet_id = subnet.odb_subnet_id
      odb_network   = "projects/${subnet.project}/locations/${subnet.location}/odbNetworks/${subnet.odbnetwork}"
      cidr_range    = subnet.cidr_range
      purpose       = subnet.purpose
      location      = subnet.location
      project       = subnet.project
      state         = subnet.state
    }
  }
}

resource "google_oracle_database_odb_subnet" "these" {
  for_each = var.gcp_odb_subnets_configuration

  odb_subnet_id = each.value.odb_subnet_id
  cidr_range    = each.value.cidr_range
  purpose       = each.value.purpose
  location      = local.odb_subnet_locations[each.key]
  project       = local.odb_subnet_project_ids[each.key]

  odbnetwork = local.odb_subnet_uses_local_odb_network[each.key] ? google_oracle_database_odb_network.these[each.value.odb_network].odb_network_id : local.odb_subnet_external_odb_network_id_segments[each.key]

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
      condition     = local.odb_subnet_locations[each.key] != null
      error_message = "Each ODB subnet must set location, default_location, reference a local ODB network with a location, or use a full odb_network resource name with a location."
    }

    precondition {
      condition     = each.value.odb_network != null
      error_message = "Each ODB subnet odb_network must be set to an ODB network key or full ODB Network resource name."
    }

    precondition {
      condition     = local.odb_subnet_uses_local_odb_network[each.key] || local.odb_subnet_uses_external_odb_network[each.key]
      error_message = "Each ODB subnet odb_network must reference an ODB network key from gcp_odb_networks_configuration or use a full ODB Network resource name."
    }

    precondition {
      condition = local.odb_subnet_uses_local_odb_network[each.key] ? (
        local.odb_subnet_project_ids[each.key] == null ||
        try(local.odb_network_project_ids[each.value.odb_network], null) == null ||
        local.odb_subnet_project_ids[each.key] == local.odb_network_project_ids[each.value.odb_network]
      ) : true
      error_message = "Each ODB subnet odb_network key must reference an ODB network in the same project."
    }

    precondition {
      condition = local.odb_subnet_uses_local_odb_network[each.key] ? (
        local.odb_subnet_locations[each.key] == null ||
        try(local.odb_network_locations[each.value.odb_network], null) == null ||
        local.odb_subnet_locations[each.key] == local.odb_network_locations[each.value.odb_network]
      ) : true
      error_message = "Each ODB subnet odb_network key must reference an ODB network in the same location."
    }

    precondition {
      condition = local.odb_subnet_uses_external_odb_network[each.key] ? (
        local.odb_subnet_project_ids[each.key] == null ||
        local.odb_subnet_external_odb_network_project_ids[each.key] == local.odb_subnet_project_ids[each.key]
      ) : true
      error_message = "Each ODB subnet full odb_network resource name must reference an ODB network in the same project."
    }

    precondition {
      condition = local.odb_subnet_uses_external_odb_network[each.key] ? (
        local.odb_subnet_locations[each.key] == null ||
        local.odb_subnet_external_odb_network_locations[each.key] == local.odb_subnet_locations[each.key]
      ) : true
      error_message = "Each ODB subnet full odb_network resource name must reference an ODB network in the same location."
    }
  }
}
