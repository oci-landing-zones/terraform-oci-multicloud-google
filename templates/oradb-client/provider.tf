provider "google" {
  region  = var.location
  project = var.project
  default_labels = {
    tf-module = "oradb-client"
    tf-source = "terraform-oci-multicloud-google"
  }
}