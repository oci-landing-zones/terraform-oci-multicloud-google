# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "project_id" { description = "GCP project ID enabled for Oracle Database@Google Cloud." }
variable "location" { description = "GCP region for Oracle Database@Google Cloud resources." }

variable "gcp_oracle_zone" {
  type    = any
  default = null
}

variable "gcp_autonomous_databases_admin_passwords" {
  description = "Admin passwords for Autonomous Databases, keyed by the same keys as gcp_autonomous_databases_configuration."
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "odb_networking_module_name" {
  type    = string
  default = "oracle-database-networking-at-gcp"
}

variable "adb_module_name" {
  type    = string
  default = "oracle-autonomous-database-at-gcp"
}

variable "adb_enable_output" {
  type    = bool
  default = true
}

variable "default_labels" {
  type    = any
  default = {}
}

variable "default_deletion_protection" {
  type    = any
  default = false
}

variable "gcp_odb_networks_configuration" {
  type    = any
  default = {}
}

variable "gcp_odb_subnets_configuration" {
  type    = any
  default = {}
}

variable "gcp_autonomous_databases_configuration" {
  type    = any
  default = {}
}
