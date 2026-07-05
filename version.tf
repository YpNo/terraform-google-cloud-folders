terraform {
  required_version = ">= 1.7.0"
  required_providers {
    google = {
      source = "hashicorp/google"
      # >= 6.15.0 for provider `universe_domain` support (Google Cloud Dedicated /
      # sovereign universes); also covers google_folder deletion_protection/policy.
      version = ">= 6.15.0"
    }
  }
}
