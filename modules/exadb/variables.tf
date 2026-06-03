# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "module_name" {
  description = "Display name for this module instance."
  type        = string
  default     = "oracle-database-at-gcp"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z]([a-z0-9_-]{0,54})?$", var.module_name))
    error_message = "module_name must be 1-55 characters, start with a lowercase letter, and contain only lowercase letters, numbers, hyphens, or underscores so it can be used in Google Cloud labels."
  }
}

variable "enable_output" {
  description = "Whether this module should emit resource outputs."
  type        = bool
  default     = true
  nullable    = false
}

variable "ssh_public_keys_file_path" {
  description = "Optional path to a file containing SSH public key for VM cluster access. If provided, the module reads this file and injects the key into all VM cluster configurations. Useful for avoiding hardcoding SSH keys in tfvars."
  type        = string
  default     = null

  validation {
    condition     = var.ssh_public_keys_file_path == null ? true : trimspace(var.ssh_public_keys_file_path) != ""
    error_message = "ssh_public_keys_file_path must be null or a non-empty file path."
  }

  validation {
    condition     = var.ssh_public_keys_file_path == null ? true : fileexists(var.ssh_public_keys_file_path)
    error_message = "ssh_public_keys_file_path must point to an existing file."
  }

  validation {
    condition = var.ssh_public_keys_file_path == null ? true : (
      fileexists(var.ssh_public_keys_file_path) ? (
        length([
          for key in split("\n", trimspace(file(var.ssh_public_keys_file_path))) :
          trimspace(key) if trimspace(key) != ""
        ]) > 0 &&
        alltrue([
          for key in split("\n", trimspace(file(var.ssh_public_keys_file_path))) :
          can(regex("^ssh-rsa[[:space:]]+[A-Za-z0-9+/]+={0,3}([[:space:]]+.+)?$", trimspace(key)))
          if trimspace(key) != ""
        ])
      ) : true
    )
    error_message = "ssh_public_keys_file_path must contain one or more valid RSA public keys in OpenSSH format, one key per non-empty line."
  }
}

variable "default_project_id" {
  description = "Default Google Cloud project ID used by resources when project_id is not set on the resource."
  type        = string
  default     = null

  validation {
    condition     = var.default_project_id == null ? true : (trimspace(var.default_project_id) != "" && var.default_project_id == trimspace(var.default_project_id) && !can(regex("[[:space:]]", var.default_project_id)))
    error_message = "default_project_id must be null or a non-empty Google Cloud project ID without leading, trailing, or internal whitespace."
  }
}

variable "default_location" {
  description = "Default Google Cloud region used by resources when location is not set on the resource."
  type        = string
  default     = null

  validation {
    condition     = var.default_location == null ? true : (trimspace(var.default_location) != "" && var.default_location == trimspace(var.default_location) && !can(regex("[[:space:]]", var.default_location)))
    error_message = "default_location must be null or a non-empty Google Cloud region without leading, trailing, or internal whitespace."
  }
}

variable "default_gcp_oracle_zone" {
  description = "Default GCP Oracle zone used by resources that support it."
  type        = string
  default     = null

  validation {
    condition     = var.default_gcp_oracle_zone == null ? true : trimspace(var.default_gcp_oracle_zone) != ""
    error_message = "default_gcp_oracle_zone must be null or a non-empty GCP Oracle zone."
  }
}

variable "default_labels" {
  description = "Default labels merged into all resources. Resource-specific labels win on key collisions."
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    condition = alltrue([
      for key, value in var.default_labels :
      can(regex("^[a-z][a-z0-9_-]{0,62}$", key)) &&
      (value == null ? false : can(regex("^[a-z0-9_-]{0,63}$", value)))
    ])
    error_message = "default_labels keys must be 1-63 characters, start with a lowercase letter, and contain only lowercase letters, numbers, underscores, or hyphens. Values must be empty or 1-63 characters containing only lowercase letters, numbers, underscores, or hyphens."
  }
}

variable "default_deletion_protection" {
  description = "Default deletion protection value for resources that support deletion_protection."
  type        = bool
  default     = true
  nullable    = false
}

variable "default_cloud_exadata_maintenance_window" {
  description = "Default maintenance window used by Cloud Exadata Infrastructure resources when properties.maintenance_window is not set."
  type = object({
    preference                       = optional(string)
    months                           = optional(list(string))
    weeks_of_month                   = optional(list(number))
    days_of_week                     = optional(list(string))
    hours_of_day                     = optional(list(number))
    lead_time_week                   = optional(number)
    patching_mode                    = optional(string)
    custom_action_timeout_mins       = optional(number)
    is_custom_action_timeout_enabled = optional(bool)
  })
  default = null

  validation {
    condition = var.default_cloud_exadata_maintenance_window == null ? true : (
      (var.default_cloud_exadata_maintenance_window.preference == null ? true : contains(["MAINTENANCE_WINDOW_PREFERENCE_UNSPECIFIED", "CUSTOM_PREFERENCE", "NO_PREFERENCE"], var.default_cloud_exadata_maintenance_window.preference)) &&
      (var.default_cloud_exadata_maintenance_window.months == null ? true : alltrue([
        for month in var.default_cloud_exadata_maintenance_window.months :
        contains(["MONTH_UNSPECIFIED", "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"], month)
      ])) &&
      (var.default_cloud_exadata_maintenance_window.weeks_of_month == null ? true : alltrue([
        for week in var.default_cloud_exadata_maintenance_window.weeks_of_month :
        contains([1, 2, 3, 4], week)
      ])) &&
      (var.default_cloud_exadata_maintenance_window.days_of_week == null ? true : alltrue([
        for day in var.default_cloud_exadata_maintenance_window.days_of_week :
        contains(["DAY_OF_WEEK_UNSPECIFIED", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"], day)
      ])) &&
      (var.default_cloud_exadata_maintenance_window.hours_of_day == null ? true : alltrue([
        for hour in var.default_cloud_exadata_maintenance_window.hours_of_day :
        contains([0, 4, 8, 12, 16, 20], hour)
      ])) &&
      (var.default_cloud_exadata_maintenance_window.lead_time_week == null ? true : var.default_cloud_exadata_maintenance_window.lead_time_week >= 1 && var.default_cloud_exadata_maintenance_window.lead_time_week <= 4) &&
      (var.default_cloud_exadata_maintenance_window.patching_mode == null ? true : contains(["PATCHING_MODE_UNSPECIFIED", "ROLLING", "NON_ROLLING"], var.default_cloud_exadata_maintenance_window.patching_mode)) &&
      (var.default_cloud_exadata_maintenance_window.custom_action_timeout_mins == null ? true : var.default_cloud_exadata_maintenance_window.custom_action_timeout_mins >= 15 && var.default_cloud_exadata_maintenance_window.custom_action_timeout_mins <= 120)
    )
    error_message = "default_cloud_exadata_maintenance_window values must use supported Oracle Database@Google Cloud enum values and documented ranges."
  }
}

variable "gcp_odb_networks_dependency" {
  description = "Externally managed ODB networks this module may depend on, keyed by logical name."
  type = map(object({
    id = string
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key in keys(var.gcp_odb_networks_dependency) :
      can(regex("^[A-Z][A-Z0-9_-]*$", key))
    ])
    error_message = "gcp_odb_networks_dependency keys must be uppercase semantic identifiers using only A-Z, 0-9, underscores, and hyphens, for example PRIMARY or SHARED_NETWORK."
  }

  validation {
    condition = alltrue([
      for network in values(var.gcp_odb_networks_dependency) :
      can(regex("^projects/[^/[:space:]]+/locations/[^/[:space:]]+/odbNetworks/[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", network.id))
    ])
    error_message = "ODB network dependency id values must use projects/{project}/locations/{location}/odbNetworks/{odb_network} format."
  }
}

variable "gcp_odb_subnets_dependency" {
  description = "Externally managed ODB subnets this module may depend on, keyed by logical name."
  type = map(object({
    id      = string
    purpose = string
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key in keys(var.gcp_odb_subnets_dependency) :
      can(regex("^[A-Z][A-Z0-9_-]*$", key))
    ])
    error_message = "gcp_odb_subnets_dependency keys must be uppercase semantic identifiers using only A-Z, 0-9, underscores, and hyphens, for example CLIENT or BACKUP."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.gcp_odb_subnets_dependency) :
      can(regex("^projects/[^/[:space:]]+/locations/[^/[:space:]]+/odbNetworks/[a-z]([a-z0-9-]{0,61}[a-z0-9])?/odbSubnets/[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", subnet.id))
    ])
    error_message = "ODB subnet dependency id values must use projects/{project}/locations/{location}/odbNetworks/{odb_network}/odbSubnets/{odb_subnet} format."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.gcp_odb_subnets_dependency) :
      contains(["CLIENT_SUBNET", "BACKUP_SUBNET"], subnet.purpose)
    ])
    error_message = "ODB subnet dependency purpose must be set to CLIENT_SUBNET or BACKUP_SUBNET on every entry."
  }
}

variable "gcp_cloud_exadata_infrastructures_dependency" {
  description = "Externally managed Cloud Exadata Infrastructures this module may depend on, keyed by logical name."
  type = map(object({
    id = string
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key in keys(var.gcp_cloud_exadata_infrastructures_dependency) :
      can(regex("^[A-Z][A-Z0-9_-]*$", key))
    ])
    error_message = "gcp_cloud_exadata_infrastructures_dependency keys must be uppercase semantic identifiers using only A-Z, 0-9, underscores, and hyphens, for example INFRA or PRIMARY_INFRA."
  }

  validation {
    condition = alltrue([
      for infrastructure in values(var.gcp_cloud_exadata_infrastructures_dependency) :
      can(regex("^projects/[^/[:space:]]+/locations/[^/[:space:]]+/cloudExadataInfrastructures/[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", infrastructure.id))
    ])
    error_message = "Cloud Exadata Infrastructure dependency id values must use projects/{project}/locations/{location}/cloudExadataInfrastructures/{infrastructure} format."
  }
}

variable "gcp_cloud_exadata_infrastructures_configuration" {
  description = "Map of Oracle Database@Google Cloud Exadata infrastructures to create."
  type = map(object({
    cloud_exadata_infrastructure_id = string
    display_name                    = optional(string)
    location                        = optional(string)
    project_id                      = optional(string)
    gcp_oracle_zone                 = optional(string)
    labels                          = optional(map(string), {})
    deletion_protection             = optional(bool)
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }))
    properties = object({
      shape                 = string
      compute_count         = optional(number)
      storage_count         = optional(number)
      total_storage_size_gb = optional(number)
      customer_contacts = optional(list(object({
        email = string
      })), [])
      maintenance_window = optional(object({
        preference                       = optional(string)
        months                           = optional(list(string))
        weeks_of_month                   = optional(list(number))
        days_of_week                     = optional(list(string))
        hours_of_day                     = optional(list(number))
        lead_time_week                   = optional(number)
        patching_mode                    = optional(string)
        custom_action_timeout_mins       = optional(number)
        is_custom_action_timeout_enabled = optional(bool)
      }))
    })
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key in keys(var.gcp_cloud_exadata_infrastructures_configuration) :
      can(regex("^[A-Z][A-Z0-9_-]*$", key))
    ])
    error_message = "gcp_cloud_exadata_infrastructures_configuration keys must be uppercase semantic identifiers using only A-Z, 0-9, underscores, and hyphens, for example INFRA or PRIMARY_INFRA."
  }

  validation {
    condition = alltrue([
      for infrastructure in var.gcp_cloud_exadata_infrastructures_configuration :
      can(regex("^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", infrastructure.cloud_exadata_infrastructure_id))
    ])
    error_message = "Cloud Exadata Infrastructure IDs must start with a lowercase letter, end with a lowercase letter or number, contain only lowercase letters, numbers, and hyphens, and be 1-63 characters long."
  }

  validation {
    condition = alltrue([
      for infrastructure in var.gcp_cloud_exadata_infrastructures_configuration :
      trimspace(infrastructure.properties.shape) != ""
    ])
    error_message = "Cloud Exadata Infrastructure properties.shape must be a non-empty string."
  }

  validation {
    condition = alltrue([
      for infrastructure in var.gcp_cloud_exadata_infrastructures_configuration :
      (infrastructure.properties.compute_count == null ? true : infrastructure.properties.compute_count > 0) &&
      (infrastructure.properties.storage_count == null ? true : infrastructure.properties.storage_count > 0) &&
      (infrastructure.properties.total_storage_size_gb == null ? true : infrastructure.properties.total_storage_size_gb > 0)
    ])
    error_message = "Cloud Exadata Infrastructure numeric capacity values must be positive when set."
  }

  validation {
    condition = alltrue(flatten([
      for infrastructure in var.gcp_cloud_exadata_infrastructures_configuration : [
        for contact in coalesce(infrastructure.properties.customer_contacts, []) :
        can(regex("^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$", contact.email))
      ]
    ]))
    error_message = "Cloud Exadata Infrastructure customer contact email values must be valid email addresses."
  }

  validation {
    condition = alltrue(flatten([
      for infrastructure in var.gcp_cloud_exadata_infrastructures_configuration : [
        for key, value in infrastructure.labels :
        can(regex("^[a-z][a-z0-9_-]{0,62}$", key)) &&
        (value == null ? false : can(regex("^[a-z0-9_-]{0,63}$", value)))
      ]
    ]))
    error_message = "Cloud Exadata Infrastructure labels keys must be 1-63 characters, start with a lowercase letter, and contain only lowercase letters, numbers, underscores, or hyphens. Values must be empty or 1-63 characters containing only lowercase letters, numbers, underscores, or hyphens."
  }

  validation {
    condition = alltrue([
      for infrastructure in var.gcp_cloud_exadata_infrastructures_configuration :
      infrastructure.project_id == null ? true : (trimspace(infrastructure.project_id) != "" && infrastructure.project_id == trimspace(infrastructure.project_id) && !can(regex("[[:space:]]", infrastructure.project_id)))
    ])
    error_message = "Cloud Exadata Infrastructure project_id values must be null or non-empty strings without leading, trailing, or internal whitespace."
  }

  validation {
    condition = alltrue([
      for infrastructure in var.gcp_cloud_exadata_infrastructures_configuration :
      infrastructure.location == null ? true : (trimspace(infrastructure.location) != "" && infrastructure.location == trimspace(infrastructure.location) && !can(regex("[[:space:]]", infrastructure.location)))
    ])
    error_message = "Cloud Exadata Infrastructure location values must be null or non-empty strings without leading, trailing, or internal whitespace."
  }

  validation {
    condition = alltrue([
      for infrastructure in var.gcp_cloud_exadata_infrastructures_configuration :
      infrastructure.gcp_oracle_zone == null ? true : trimspace(infrastructure.gcp_oracle_zone) != ""
    ])
    error_message = "Cloud Exadata Infrastructure gcp_oracle_zone values must be null or non-empty strings."
  }

  validation {
    condition = alltrue([
      for infrastructure in var.gcp_cloud_exadata_infrastructures_configuration :
      infrastructure.properties.maintenance_window == null ? true : (
        (infrastructure.properties.maintenance_window.preference == null ? true : contains(["MAINTENANCE_WINDOW_PREFERENCE_UNSPECIFIED", "CUSTOM_PREFERENCE", "NO_PREFERENCE"], infrastructure.properties.maintenance_window.preference)) &&
        (infrastructure.properties.maintenance_window.months == null ? true : alltrue([
          for month in infrastructure.properties.maintenance_window.months :
          contains(["MONTH_UNSPECIFIED", "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"], month)
        ])) &&
        (infrastructure.properties.maintenance_window.weeks_of_month == null ? true : alltrue([
          for week in infrastructure.properties.maintenance_window.weeks_of_month :
          contains([1, 2, 3, 4], week)
        ])) &&
        (infrastructure.properties.maintenance_window.days_of_week == null ? true : alltrue([
          for day in infrastructure.properties.maintenance_window.days_of_week :
          contains(["DAY_OF_WEEK_UNSPECIFIED", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"], day)
        ])) &&
        (infrastructure.properties.maintenance_window.hours_of_day == null ? true : alltrue([
          for hour in infrastructure.properties.maintenance_window.hours_of_day :
          contains([0, 4, 8, 12, 16, 20], hour)
        ])) &&
        (infrastructure.properties.maintenance_window.lead_time_week == null ? true : infrastructure.properties.maintenance_window.lead_time_week >= 1 && infrastructure.properties.maintenance_window.lead_time_week <= 4) &&
        (infrastructure.properties.maintenance_window.patching_mode == null ? true : contains(["PATCHING_MODE_UNSPECIFIED", "ROLLING", "NON_ROLLING"], infrastructure.properties.maintenance_window.patching_mode)) &&
        (infrastructure.properties.maintenance_window.custom_action_timeout_mins == null ? true : infrastructure.properties.maintenance_window.custom_action_timeout_mins >= 15 && infrastructure.properties.maintenance_window.custom_action_timeout_mins <= 120)
      )
    ])
    error_message = "Cloud Exadata Infrastructure maintenance_window values must use supported Oracle Database@Google Cloud enum values and documented ranges."
  }
}

variable "gcp_cloud_vm_clusters_configuration" {
  description = "Map of Oracle Database@Google Cloud VM clusters to create."
  type = map(object({
    cloud_vm_cluster_id = string
    display_name        = optional(string)
    location            = optional(string)
    project_id          = optional(string)
    labels              = optional(map(string), {})
    deletion_protection = optional(bool)
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }))

    exadata_infrastructure = optional(string)

    odb_network       = optional(string)
    odb_subnet        = optional(string)
    backup_odb_subnet = optional(string)

    properties = object({
      license_type             = string
      gi_version               = optional(string)
      ssh_public_keys          = optional(list(string))
      node_count               = optional(number)
      ocpu_count               = optional(number)
      memory_size_gb           = optional(number)
      db_node_storage_size_gb  = optional(number)
      data_storage_size_tb     = optional(number)
      disk_redundancy          = optional(string)
      sparse_diskgroup_enabled = optional(bool)
      local_backup_enabled     = optional(bool)
      hostname_prefix          = optional(string)
      cpu_core_count           = number
      db_server_ocids          = optional(list(string))
      cluster_name             = optional(string)
      time_zone = optional(object({
        id      = optional(string)
        version = optional(string)
      }))
      diagnostics_data_collection_options = optional(object({
        diagnostics_events_enabled = optional(bool)
        health_monitoring_enabled  = optional(bool)
        incident_logs_enabled      = optional(bool)
      }))
    })
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key in keys(var.gcp_cloud_vm_clusters_configuration) :
      can(regex("^[A-Z][A-Z0-9_-]*$", key))
    ])
    error_message = "gcp_cloud_vm_clusters_configuration keys must be uppercase semantic identifiers using only A-Z, 0-9, underscores, and hyphens, for example PRIMARY or PROD_CLUSTER."
  }

  validation {
    condition = alltrue([
      for cluster in var.gcp_cloud_vm_clusters_configuration :
      can(regex("^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", cluster.cloud_vm_cluster_id))
    ])
    error_message = "Cloud VM cluster IDs must start with a lowercase letter, end with a lowercase letter or number, contain only lowercase letters, numbers, and hyphens, and be 1-63 characters long."
  }

  validation {
    condition = alltrue([
      for cluster in var.gcp_cloud_vm_clusters_configuration :
      cluster.exadata_infrastructure != null
    ])
    error_message = "Each Cloud VM cluster must set exadata_infrastructure to a resource name or dependency key."
  }

  validation {
    condition = alltrue([
      for cluster in var.gcp_cloud_vm_clusters_configuration :
      cluster.odb_network != null &&
      cluster.odb_subnet != null &&
      cluster.backup_odb_subnet != null
    ])
    error_message = "Each Cloud VM cluster must set ODB network, client ODB subnet, and backup ODB subnet references."
  }

  validation {
    condition = alltrue([
      for cluster in var.gcp_cloud_vm_clusters_configuration :
      (cluster.exadata_infrastructure == null ? true : (!can(regex("^projects/", cluster.exadata_infrastructure)) || can(regex("^projects/[^/[:space:]]+/locations/[^/[:space:]]+/cloudExadataInfrastructures/[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", cluster.exadata_infrastructure)))) &&
      (cluster.odb_network == null ? true : (!can(regex("^projects/", cluster.odb_network)) || can(regex("^projects/[^/[:space:]]+/locations/[^/[:space:]]+/odbNetworks/[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", cluster.odb_network)))) &&
      (cluster.odb_subnet == null ? true : (!can(regex("^projects/", cluster.odb_subnet)) || can(regex("^projects/[^/[:space:]]+/locations/[^/[:space:]]+/odbNetworks/[a-z]([a-z0-9-]{0,61}[a-z0-9])?/odbSubnets/[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", cluster.odb_subnet)))) &&
      (cluster.backup_odb_subnet == null ? true : (!can(regex("^projects/", cluster.backup_odb_subnet)) || can(regex("^projects/[^/[:space:]]+/locations/[^/[:space:]]+/odbNetworks/[a-z]([a-z0-9-]{0,61}[a-z0-9])?/odbSubnets/[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", cluster.backup_odb_subnet))))
    ])
    error_message = "Cloud VM cluster resource references that start with projects/ must use the full resource name formats documented by the Google provider."
  }

  validation {
    condition = alltrue([
      for cluster in var.gcp_cloud_vm_clusters_configuration : (
        (cluster.exadata_infrastructure == null || (trimspace(cluster.exadata_infrastructure) != "" && cluster.exadata_infrastructure == trimspace(cluster.exadata_infrastructure) && !can(regex("[[:space:]]", cluster.exadata_infrastructure)))) &&
        (cluster.odb_network == null || (trimspace(cluster.odb_network) != "" && cluster.odb_network == trimspace(cluster.odb_network) && !can(regex("[[:space:]]", cluster.odb_network)))) &&
        (cluster.odb_subnet == null || (trimspace(cluster.odb_subnet) != "" && cluster.odb_subnet == trimspace(cluster.odb_subnet) && !can(regex("[[:space:]]", cluster.odb_subnet)))) &&
        (cluster.backup_odb_subnet == null || (trimspace(cluster.backup_odb_subnet) != "" && cluster.backup_odb_subnet == trimspace(cluster.backup_odb_subnet) && !can(regex("[[:space:]]", cluster.backup_odb_subnet))))
      )
    ])
    error_message = "Cloud VM cluster Exadata infrastructure, ODB network, and ODB subnet reference fields must not be empty or contain whitespace when set."
  }

  validation {
    condition = alltrue(flatten([
      for cluster in var.gcp_cloud_vm_clusters_configuration : [
        for key, value in cluster.labels :
        can(regex("^[a-z][a-z0-9_-]{0,62}$", key)) &&
        (value == null ? false : can(regex("^[a-z0-9_-]{0,63}$", value)))
      ]
    ]))
    error_message = "Cloud VM cluster labels keys must be 1-63 characters, start with a lowercase letter, and contain only lowercase letters, numbers, underscores, or hyphens. Values must be empty or 1-63 characters containing only lowercase letters, numbers, underscores, or hyphens."
  }

  validation {
    condition = alltrue([
      for cluster in var.gcp_cloud_vm_clusters_configuration :
      cluster.project_id == null ? true : (trimspace(cluster.project_id) != "" && cluster.project_id == trimspace(cluster.project_id) && !can(regex("[[:space:]]", cluster.project_id)))
    ])
    error_message = "Cloud VM cluster project_id values must be null or non-empty strings without leading, trailing, or internal whitespace."
  }

  validation {
    condition = alltrue([
      for cluster in var.gcp_cloud_vm_clusters_configuration :
      cluster.location == null ? true : (trimspace(cluster.location) != "" && cluster.location == trimspace(cluster.location) && !can(regex("[[:space:]]", cluster.location)))
    ])
    error_message = "Cloud VM cluster location values must be null or non-empty strings without leading, trailing, or internal whitespace."
  }

  validation {
    condition = alltrue([
      for cluster in var.gcp_cloud_vm_clusters_configuration :
      contains(["LICENSE_TYPE_UNSPECIFIED", "LICENSE_INCLUDED", "BRING_YOUR_OWN_LICENSE"], cluster.properties.license_type)
    ])
    error_message = "Cloud VM cluster license_type must be LICENSE_TYPE_UNSPECIFIED, LICENSE_INCLUDED, or BRING_YOUR_OWN_LICENSE."
  }

  validation {
    condition = alltrue([
      for cluster in var.gcp_cloud_vm_clusters_configuration :
      cluster.properties.gi_version != null && trimspace(cluster.properties.gi_version) != ""
    ])
    error_message = "Cloud VM cluster gi_version is required by the Oracle Database@Google Cloud API and must be a non-empty Grid Infrastructure version, for example 19.0.0.0."
  }

  validation {
    condition = alltrue([
      for cluster in var.gcp_cloud_vm_clusters_configuration :
      cluster.properties.cpu_core_count >= 4 &&
      (cluster.properties.node_count == null ? true : cluster.properties.node_count >= 2) &&
      (cluster.properties.ocpu_count == null ? true : cluster.properties.ocpu_count >= 0.1) &&
      (cluster.properties.memory_size_gb == null ? true : cluster.properties.memory_size_gb >= 60) &&
      (cluster.properties.db_node_storage_size_gb == null ? true : cluster.properties.db_node_storage_size_gb >= 120) &&
      (cluster.properties.data_storage_size_tb == null ? true : cluster.properties.data_storage_size_tb >= 2)
    ])
    error_message = "Cloud VM cluster capacity values must meet minimums: cpu_core_count >= 4, node_count >= 2 when set, ocpu_count >= 0.1 when set, memory_size_gb >= 60 when set, db_node_storage_size_gb >= 120 when set, and data_storage_size_tb >= 2 when set."
  }

  validation {
    condition = alltrue([
      for cluster in var.gcp_cloud_vm_clusters_configuration :
      cluster.properties.disk_redundancy == null ? true : contains(["DISK_REDUNDANCY_UNSPECIFIED", "HIGH", "NORMAL"], cluster.properties.disk_redundancy)
    ])
    error_message = "Cloud VM cluster disk_redundancy must be DISK_REDUNDANCY_UNSPECIFIED, HIGH, or NORMAL when set."
  }

  validation {
    condition = alltrue([
      for cluster in var.gcp_cloud_vm_clusters_configuration :
      cluster.properties.hostname_prefix == null ? true : can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,11}$", cluster.properties.hostname_prefix))
    ])
    error_message = "Cloud VM cluster hostname_prefix must start with a letter, contain only letters, numbers, and hyphens, and be 1-12 characters long."
  }

  validation {
    condition = alltrue([
      for cluster in var.gcp_cloud_vm_clusters_configuration :
      cluster.properties.cluster_name == null ? true : can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,10}$", cluster.properties.cluster_name))
    ])
    error_message = "Cloud VM cluster cluster_name must start with a letter, contain only letters, numbers, and hyphens, and be 1-11 characters long."
  }

  validation {
    condition = alltrue(flatten([
      for cluster in var.gcp_cloud_vm_clusters_configuration :
      cluster.properties.ssh_public_keys == null ? [true] : [
        for key in cluster.properties.ssh_public_keys :
        can(regex("^ssh-rsa[[:space:]]+[A-Za-z0-9+/]+={0,3}([[:space:]]+.+)?$", trimspace(key)))
      ]
    ]))
    error_message = "Cloud VM cluster ssh_public_keys entries must be valid RSA public keys in OpenSSH format: ssh-rsa <base64> [comment]."
  }

  validation {
    condition = alltrue(flatten([
      for cluster in var.gcp_cloud_vm_clusters_configuration :
      cluster.properties.db_server_ocids == null ? [true] : [
        for ocid in cluster.properties.db_server_ocids :
        ocid == trimspace(ocid) &&
        can(regex("^ocid1[.]dbserver[.][^./[:space:]]+[.][^./[:space:]]+[.][^/[:space:]]+$", ocid))
      ]
    ]))
    error_message = "Cloud VM cluster db_server_ocids entries must be complete DB server OCIDs using ocid1.dbserver.<realm>.<region>.<id> format, for example ocid1.dbserver.oc1.<region>.<id>."
  }
}
