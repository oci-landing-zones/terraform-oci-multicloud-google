# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  gcp_resource_id_segment_pattern   = "[a-z]([a-z0-9-]{0,61}[a-z0-9])?"
  odb_network_resource_name_pattern = "^projects/[^/[:space:]]+/locations/[^/[:space:]]+/odbNetworks/${local.gcp_resource_id_segment_pattern}$"
  odb_subnet_resource_name_pattern  = "^projects/[^/[:space:]]+/locations/[^/[:space:]]+/odbNetworks/${local.gcp_resource_id_segment_pattern}/odbSubnets/${local.gcp_resource_id_segment_pattern}$"

  autonomous_database_odb_networks = {
    for key, adb in var.gcp_autonomous_databases_configuration : key =>
    can(regex(local.odb_network_resource_name_pattern, adb.odb_network)) ? adb.odb_network : try(local.gcp_odb_networks_dependency[adb.odb_network].id, null)
  }

  autonomous_database_odb_subnets = {
    for key, adb in var.gcp_autonomous_databases_configuration : key =>
    can(regex(local.odb_subnet_resource_name_pattern, adb.odb_subnet)) ? adb.odb_subnet : try(local.gcp_odb_subnets_dependency[adb.odb_subnet].id, null)
  }

  autonomous_database_odb_subnet_dependency_ids_with_purpose = distinct([
    for subnet in values(local.gcp_odb_subnets_dependency) : subnet.id
    if try(subnet.id, null) != null && try(subnet.purpose, null) != null
  ])

  autonomous_database_odb_subnet_dependency_purposes_by_id = {
    for subnet_id in local.autonomous_database_odb_subnet_dependency_ids_with_purpose : subnet_id => distinct([
      for subnet in values(local.gcp_odb_subnets_dependency) : subnet.purpose
      if try(subnet.id, null) == subnet_id && try(subnet.purpose, null) != null
    ])
  }

  autonomous_database_odb_subnet_purposes = {
    for key, odb_subnet in local.autonomous_database_odb_subnets : key =>
    odb_subnet == null ? [] : try(local.autonomous_database_odb_subnet_dependency_purposes_by_id[odb_subnet], [])
  }

  autonomous_database_locations = {
    for key, adb in var.gcp_autonomous_databases_configuration : key =>
    adb.location != null ? adb.location : var.default_location
  }

  autonomous_database_selected_odb_network_segments = {
    for key, odb_network in local.autonomous_database_odb_networks : key => (
      odb_network == null ? null : {
        project  = try(split("/", odb_network)[1], null)
        location = try(split("/", odb_network)[3], null)
        segment  = try(split("/", odb_network)[5], null)
      }
    )
  }

  autonomous_database_subnet_parent_segments = {
    for key, odb_subnet in local.autonomous_database_odb_subnets : key => (
      odb_subnet == null ? null : {
        project  = try(split("/", odb_subnet)[1], null)
        location = try(split("/", odb_subnet)[3], null)
        segment  = try(split("/", odb_subnet)[5], null)
      }
    )
  }

  gcp_autonomous_databases_output = {
    for key, adb in google_oracle_database_autonomous_database.these : key => {
      id                                    = adb.id
      name                                  = adb.name
      location                              = adb.location
      project                               = adb.project
      ocid                                  = try(adb.properties[0].ocid, null)
      state                                 = try(adb.properties[0].state, null)
      oci_url                               = try(adb.properties[0].oci_url, null)
      oci_region                            = try(regex("region=([^?&/]+)", adb.properties[0].oci_url)[0], null)
      oci_tenant                            = try(regex("tenant=([^?&/]+)", adb.properties[0].oci_url)[0], null)
      oci_compartment_id                    = try(regex("compartmentId=([^?&/]+)", adb.properties[0].oci_url)[0], null)
      connection_strings                    = try(adb.properties[0].connection_strings, null)
      connection_urls                       = try(adb.properties[0].connection_urls, null)
      private_endpoint                      = try(adb.properties[0].private_endpoint, null)
      private_endpoint_ip                   = try(adb.properties[0].private_endpoint_ip, null)
      private_endpoint_label                = try(adb.properties[0].private_endpoint_label, null)
      sql_web_developer_url                 = try(adb.properties[0].sql_web_developer_url, null)
      operations_insights_state             = try(adb.properties[0].operations_insights_state, null)
      role                                  = try(adb.properties[0].role, null)
      peer_autonomous_databases             = try(adb.peer_autonomous_databases, null)
      peer_db_ids                           = try(adb.properties[0].peer_db_ids, null)
      permission_level                      = try(adb.properties[0].permission_level, null)
      is_local_data_guard_enabled           = try(adb.properties[0].is_local_data_guard_enabled, null)
      local_disaster_recovery_type          = try(adb.properties[0].local_disaster_recovery_type, null)
      local_standby_db                      = try(adb.properties[0].local_standby_db, null)
      disaster_recovery_supported_locations = try(adb.disaster_recovery_supported_locations, null)
    }
  }
}

resource "google_oracle_database_autonomous_database" "these" {
  for_each = var.gcp_autonomous_databases_configuration

  autonomous_database_id = each.value.autonomous_database_id
  location               = each.value.location != null ? each.value.location : var.default_location
  project                = each.value.project_id != null ? each.value.project_id : var.default_project_id
  display_name           = each.value.display_name != null ? each.value.display_name : each.value.autonomous_database_id
  database               = each.value.database
  admin_password         = try(var.gcp_autonomous_databases_admin_passwords[each.key], null)

  odb_network = local.autonomous_database_odb_networks[each.key]
  odb_subnet  = local.autonomous_database_odb_subnets[each.key]

  labels              = merge(local.module_tag, local.default_labels, each.value.labels)
  deletion_protection = each.value.deletion_protection != null ? each.value.deletion_protection : var.default_deletion_protection

  dynamic "properties" {
    for_each = each.value.properties == null ? [] : [each.value.properties]
    content {
      db_workload                     = properties.value.db_workload
      license_type                    = properties.value.license_type
      compute_count                   = properties.value.compute_count
      cpu_core_count                  = properties.value.cpu_core_count
      data_storage_size_tb            = properties.value.data_storage_size_tb
      data_storage_size_gb            = properties.value.data_storage_size_gb
      db_version                      = properties.value.db_version
      db_edition                      = properties.value.db_edition
      character_set                   = properties.value.character_set
      n_character_set                 = properties.value.n_character_set
      private_endpoint_ip             = properties.value.private_endpoint_ip
      private_endpoint_label          = properties.value.private_endpoint_label
      is_auto_scaling_enabled         = properties.value.is_auto_scaling_enabled
      is_storage_auto_scaling_enabled = properties.value.is_storage_auto_scaling_enabled
      backup_retention_period_days    = properties.value.backup_retention_period_days
      maintenance_schedule_type       = properties.value.maintenance_schedule_type
      mtls_connection_required        = properties.value.mtls_connection_required
      secret_id                       = properties.value.secret_id
      vault_id                        = properties.value.vault_id

      dynamic "customer_contacts" {
        for_each = properties.value.customer_contacts
        content {
          email = customer_contacts.value.email
        }
      }
    }
  }

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
      admin_password,
      properties[0].compute_count,
      properties[0].cpu_core_count,
      properties[0].data_storage_size_tb,
      properties[0].data_storage_size_gb,
      properties[0].db_version,
      properties[0].db_edition,
      properties[0].is_auto_scaling_enabled,
      properties[0].is_storage_auto_scaling_enabled,
      properties[0].backup_retention_period_days,
    ]

    precondition {
      condition     = each.value.location != null || var.default_location != null
      error_message = "Each Autonomous Database must set location or default_location."
    }

    precondition {
      condition     = try(each.value.properties.db_workload, null) != null && try(each.value.properties.license_type, null) != null
      error_message = "Autonomous database '${each.key}': properties.db_workload and properties.license_type are required by the Google provider."
    }

    precondition {
      condition     = local.autonomous_database_odb_networks[each.key] != null
      error_message = "Autonomous database '${each.key}': odb_network must be a full ODB Network resource name or a key from gcp_odb_networks_dependency. Available keys: ${join(", ", keys(local.gcp_odb_networks_dependency))}."
    }

    precondition {
      condition     = local.autonomous_database_odb_subnets[each.key] != null
      error_message = "Autonomous database '${each.key}': odb_subnet must be a full ODB Subnet resource name or a key from gcp_odb_subnets_dependency. Available keys: ${join(", ", keys(local.gcp_odb_subnets_dependency))}."
    }

    precondition {
      condition = (
        local.autonomous_database_selected_odb_network_segments[each.key] == null ||
        local.autonomous_database_subnet_parent_segments[each.key] == null ||
        (
          local.autonomous_database_selected_odb_network_segments[each.key].segment != null &&
          local.autonomous_database_subnet_parent_segments[each.key].segment != null &&
          local.autonomous_database_selected_odb_network_segments[each.key].project == local.autonomous_database_subnet_parent_segments[each.key].project &&
          local.autonomous_database_selected_odb_network_segments[each.key].location == local.autonomous_database_subnet_parent_segments[each.key].location &&
          local.autonomous_database_selected_odb_network_segments[each.key].segment == local.autonomous_database_subnet_parent_segments[each.key].segment
        )
      )
      error_message = "Autonomous database '${each.key}': odb_subnet must belong to the selected odb_network and share the same project and location."
    }

    precondition {
      condition = (
        local.autonomous_database_locations[each.key] == null ||
        local.autonomous_database_selected_odb_network_segments[each.key] == null ||
        local.autonomous_database_selected_odb_network_segments[each.key].location == null ||
        local.autonomous_database_locations[each.key] == local.autonomous_database_selected_odb_network_segments[each.key].location
      )
      error_message = "Autonomous database '${each.key}': location must match the selected odb_network location."
    }

    precondition {
      condition = (
        local.autonomous_database_locations[each.key] == null ||
        local.autonomous_database_subnet_parent_segments[each.key] == null ||
        local.autonomous_database_subnet_parent_segments[each.key].location == null ||
        local.autonomous_database_locations[each.key] == local.autonomous_database_subnet_parent_segments[each.key].location
      )
      error_message = "Autonomous database '${each.key}': location must match the selected odb_subnet location."
    }

    precondition {
      condition     = alltrue([for purpose in local.autonomous_database_odb_subnet_purposes[each.key] : purpose == "CLIENT_SUBNET"])
      error_message = "Autonomous database '${each.key}': odb_subnet must reference an ODB subnet with purpose CLIENT_SUBNET when the subnet purpose is known from gcp_odb_subnets_dependency."
    }
  }
}
