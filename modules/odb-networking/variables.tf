# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "module_name" {
  description = "Display name for this module instance."
  type        = string
  default     = "oracle-database-networking-at-gcp"
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
  description = "Default GCP Oracle zone used by ODB Network resources when gcp_oracle_zone is not set."
  type        = string
  default     = null

  validation {
    condition     = var.default_gcp_oracle_zone == null ? true : (trimspace(var.default_gcp_oracle_zone) != "" && var.default_gcp_oracle_zone == trimspace(var.default_gcp_oracle_zone) && !can(regex("[[:space:]]", var.default_gcp_oracle_zone)))
    error_message = "default_gcp_oracle_zone must be null or a non-empty GCP Oracle zone without leading, trailing, or internal whitespace."
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

variable "default_deletion_policy" {
  description = "Default deletion policy used by resources that support deletion_policy. PREVENT blocks Terraform destroys unless overridden."
  type        = string
  default     = "PREVENT"
  nullable    = false

  validation {
    condition     = contains(["DELETE", "PREVENT", "ABANDON"], var.default_deletion_policy)
    error_message = "default_deletion_policy must be one of DELETE, PREVENT, or ABANDON."
  }
}

variable "gcp_odb_networks_configuration" {
  description = "Map of Oracle Database@Google Cloud ODB networks to create."
  type = map(object({
    odb_network_id      = string
    network             = string
    location            = optional(string)
    project_id          = optional(string)
    gcp_oracle_zone     = optional(string)
    labels              = optional(map(string), {})
    deletion_protection = optional(bool)
    deletion_policy     = optional(string)
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }))
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key in keys(var.gcp_odb_networks_configuration) :
      can(regex("^[A-Z][A-Z0-9_-]*$", key))
    ])
    error_message = "gcp_odb_networks_configuration keys must be uppercase semantic identifiers using only A-Z, 0-9, underscores, and hyphens, for example PRIMARY or SHARED_NETWORK."
  }

  validation {
    condition = alltrue([
      for network in var.gcp_odb_networks_configuration :
      can(regex("^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", network.odb_network_id))
    ])
    error_message = "ODB network IDs must start with a lowercase letter, end with a lowercase letter or number, contain only lowercase letters, numbers, and hyphens, and be 1-63 characters long."
  }

  validation {
    condition = alltrue([
      for network in var.gcp_odb_networks_configuration :
      can(regex("^projects/[^/[:space:]]+/global/networks/[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", network.network))
    ])
    error_message = "ODB network network values must use projects/{project}/global/networks/{network} format, where network is a lowercase Google Cloud VPC network ID segment."
  }

  validation {
    condition = alltrue([
      for network in var.gcp_odb_networks_configuration :
      try((network.project_id != null ? network.project_id : var.default_project_id) == null ? true : (network.project_id != null ? network.project_id : var.default_project_id) == split("/", network.network)[1], true)
    ])
    error_message = "ODB network project_id or default_project_id must match the project segment in network when a resource project is known."
  }

  validation {
    condition = alltrue(flatten([
      for network in var.gcp_odb_networks_configuration : [
        for key, value in network.labels :
        can(regex("^[a-z][a-z0-9_-]{0,62}$", key)) &&
        (value == null ? false : can(regex("^[a-z0-9_-]{0,63}$", value)))
      ]
    ]))
    error_message = "ODB network labels keys must be 1-63 characters, start with a lowercase letter, and contain only lowercase letters, numbers, underscores, or hyphens. Values must be empty or 1-63 characters containing only lowercase letters, numbers, underscores, or hyphens."
  }

  validation {
    condition = alltrue([
      for network in var.gcp_odb_networks_configuration :
      network.project_id == null ? true : (trimspace(network.project_id) != "" && network.project_id == trimspace(network.project_id) && !can(regex("[[:space:]]", network.project_id)))
    ])
    error_message = "ODB network project_id values must be null or non-empty strings without leading, trailing, or internal whitespace."
  }

  validation {
    condition = alltrue([
      for network in var.gcp_odb_networks_configuration :
      network.location == null ? true : (trimspace(network.location) != "" && network.location == trimspace(network.location) && !can(regex("[[:space:]]", network.location)))
    ])
    error_message = "ODB network location values must be null or non-empty strings without leading, trailing, or internal whitespace."
  }

  validation {
    condition = alltrue([
      for network in var.gcp_odb_networks_configuration :
      network.gcp_oracle_zone == null ? true : (trimspace(network.gcp_oracle_zone) != "" && network.gcp_oracle_zone == trimspace(network.gcp_oracle_zone) && !can(regex("[[:space:]]", network.gcp_oracle_zone)))
    ])
    error_message = "ODB network gcp_oracle_zone values must be null or non-empty strings without leading, trailing, or internal whitespace."
  }

  validation {
    condition = alltrue([
      for network in var.gcp_odb_networks_configuration :
      network.deletion_policy == null ? true : contains(["DELETE", "PREVENT", "ABANDON"], network.deletion_policy)
    ])
    error_message = "ODB network deletion_policy values must be null or one of DELETE, PREVENT, or ABANDON."
  }
}

variable "gcp_odb_subnets_configuration" {
  description = "Map of Oracle Database@Google Cloud ODB subnets to create."
  type = map(object({
    odb_subnet_id       = string
    cidr_range          = string
    purpose             = string
    odb_network         = optional(string)
    location            = optional(string)
    project_id          = optional(string)
    labels              = optional(map(string), {})
    deletion_protection = optional(bool)
    deletion_policy     = optional(string)
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }))
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key in keys(var.gcp_odb_subnets_configuration) :
      can(regex("^[A-Z][A-Z0-9_-]*$", key))
    ])
    error_message = "gcp_odb_subnets_configuration keys must be uppercase semantic identifiers using only A-Z, 0-9, underscores, and hyphens, for example CLIENT or BACKUP."
  }

  validation {
    condition = alltrue([
      for subnet in var.gcp_odb_subnets_configuration :
      can(regex("^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", subnet.odb_subnet_id))
    ])
    error_message = "ODB subnet IDs must start with a lowercase letter, end with a lowercase letter or number, contain only lowercase letters, numbers, and hyphens, and be 1-63 characters long."
  }

  validation {
    condition = alltrue([
      for subnet in var.gcp_odb_subnets_configuration :
      try(cidrhost(subnet.cidr_range, 0) == split("/", subnet.cidr_range)[0], false)
    ])
    error_message = "ODB subnet cidr_range values must be valid canonical CIDR blocks whose address is the network address."
  }

  validation {
    condition = alltrue([
      for subnet in var.gcp_odb_subnets_configuration :
      try(
        (
          tonumber(split(".", split("/", subnet.cidr_range)[0])[0]) == 10 &&
          tonumber(split("/", subnet.cidr_range)[1]) >= 8
          ) || (
          tonumber(split(".", split("/", subnet.cidr_range)[0])[0]) == 172 &&
          tonumber(split(".", split("/", subnet.cidr_range)[0])[1]) >= 16 &&
          tonumber(split(".", split("/", subnet.cidr_range)[0])[1]) <= 31 &&
          tonumber(split("/", subnet.cidr_range)[1]) >= 12
          ) || (
          tonumber(split(".", split("/", subnet.cidr_range)[0])[0]) == 192 &&
          tonumber(split(".", split("/", subnet.cidr_range)[0])[1]) == 168 &&
          tonumber(split("/", subnet.cidr_range)[1]) >= 16
        ),
        false
      )
    ])
    error_message = "ODB subnet cidr_range values must be RFC1918 private IPv4 CIDR blocks and must not use Oracle-reserved 100.64.0.0/10 space."
  }

  validation {
    condition = alltrue([
      for subnet in var.gcp_odb_subnets_configuration : contains(["CLIENT_SUBNET", "BACKUP_SUBNET"], subnet.purpose)
    ])
    error_message = "ODB subnet purpose must be either CLIENT_SUBNET or BACKUP_SUBNET."
  }

  validation {
    condition = alltrue([
      for subnet in var.gcp_odb_subnets_configuration :
      subnet.odb_network != null
    ])
    error_message = "Each ODB subnet must set odb_network to an ODB network key or full ODB Network resource name."
  }

  validation {
    condition = alltrue([
      for subnet in var.gcp_odb_subnets_configuration :
      subnet.odb_network == null ? true : (
        !can(regex("^projects/", subnet.odb_network)) ||
        can(regex("^projects/[^/[:space:]]+/locations/[^/[:space:]]+/odbNetworks/[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", subnet.odb_network))
      )
    ])
    error_message = "ODB subnet odb_network values must be either keys from gcp_odb_networks_configuration or full resource names using projects/{project}/locations/{location}/odbNetworks/{odb_network}."
  }

  validation {
    condition = alltrue([
      for subnet in var.gcp_odb_subnets_configuration : (
        subnet.odb_network == null || (trimspace(subnet.odb_network) != "" && subnet.odb_network == trimspace(subnet.odb_network) && !can(regex("[[:space:]]", subnet.odb_network)))
      )
    ])
    error_message = "ODB subnet odb_network must not be empty or contain whitespace when set."
  }

  validation {
    condition = alltrue(flatten([
      for subnet in var.gcp_odb_subnets_configuration : [
        for key, value in subnet.labels :
        can(regex("^[a-z][a-z0-9_-]{0,62}$", key)) &&
        (value == null ? false : can(regex("^[a-z0-9_-]{0,63}$", value)))
      ]
    ]))
    error_message = "ODB subnet labels keys must be 1-63 characters, start with a lowercase letter, and contain only lowercase letters, numbers, underscores, or hyphens. Values must be empty or 1-63 characters containing only lowercase letters, numbers, underscores, or hyphens."
  }

  validation {
    condition = alltrue([
      for subnet in var.gcp_odb_subnets_configuration :
      subnet.project_id == null ? true : (trimspace(subnet.project_id) != "" && subnet.project_id == trimspace(subnet.project_id) && !can(regex("[[:space:]]", subnet.project_id)))
    ])
    error_message = "ODB subnet project_id values must be null or non-empty strings without leading, trailing, or internal whitespace."
  }

  validation {
    condition = alltrue([
      for subnet in var.gcp_odb_subnets_configuration :
      subnet.location == null ? true : (trimspace(subnet.location) != "" && subnet.location == trimspace(subnet.location) && !can(regex("[[:space:]]", subnet.location)))
    ])
    error_message = "ODB subnet location values must be null or non-empty strings without leading, trailing, or internal whitespace."
  }

  validation {
    condition = alltrue([
      for subnet in var.gcp_odb_subnets_configuration :
      subnet.deletion_policy == null ? true : contains(["DELETE", "PREVENT", "ABANDON"], subnet.deletion_policy)
    ])
    error_message = "ODB subnet deletion_policy values must be null or one of DELETE, PREVENT, or ABANDON."
  }
}
