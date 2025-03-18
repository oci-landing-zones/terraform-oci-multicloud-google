output "adbs_ocid" {
  description = "OCID for this Autonomous Database@Google Cloud"
  value = module.gcp-oci-adbs-quickstart.oci_adbs_ocid
}

output "adbs_dbid" {
  description = "DBID of this Autonomous Database@Google Cloud"
  value = module.gcp-oci-adbs-quickstart.autonomous_database_id
}

output "connstr" {
  description = "Connection strings of this Autonomous Database@Google Cloud"
  value = module.gcp-oci-adbs-quickstart.resource.properties[0].connection_strings[0].profiles[0].value
}

output "location" {
  description = "Location of this Autonomous Database@Google Cloud"
  value = module.gcp-oci-adbs-quickstart.resource.location
}