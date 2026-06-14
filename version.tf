terraform {
  required_version = ">= 1.7.0"
  required_providers {
    google = {
      source = "hashicorp/google"
      # google_folder.deletion_protection and deletion_policy require >= 5.0.
      version = ">= 5.0.0"
    }
  }
}
