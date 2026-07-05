terraform {
  required_version = ">= 1.7.0"
  required_providers {
    google = {
      source = "hashicorp/google"
      # >= 6.15.0 for provider `universe_domain` support (sovereign universes).
      version = ">= 6.15.0"
    }
  }
}
