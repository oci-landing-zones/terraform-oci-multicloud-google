# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "module_name" {
  description = "The module instance name."
  value       = var.module_name
}

output "gcp_autonomous_databases" {
  description = "Created Autonomous Databases, keyed by input key."
  value       = var.enable_output ? local.gcp_autonomous_databases_output : null
}
