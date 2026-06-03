# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "database_homes" {
  description = "OCI DB Homes created by the downstream OCI Exadata module."
  value       = module.oci_exadata_database.database_homes
}

output "databases" {
  description = "OCI CDBs created by the downstream OCI Exadata module."
  value       = module.oci_exadata_database.databases
}

output "pluggable_databases" {
  description = "OCI PDBs created by the downstream OCI Exadata module."
  value       = module.oci_exadata_database.pluggable_databases
}
