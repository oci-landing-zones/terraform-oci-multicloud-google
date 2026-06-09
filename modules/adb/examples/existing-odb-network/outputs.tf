# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "gcp_autonomous_databases" {
  description = "Created Autonomous Database resources, keyed by input key."
  value       = module.oracle_autonomous_database_at_gcp.gcp_autonomous_databases
}
