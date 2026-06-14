module "folders" {
  source = "../../"

  org_domain = "example.com"

  # Module-wide defaults; override per folder as needed.
  deletion_protection = true
  deletion_policy     = "DELETE"

  folders = {
    "Root1"                = {}
    "Root1/Team A"         = {}
    "Root1/Team A/Backend" = { deletion_protection = false }
    "Root1/Team B"         = {}
    "Root2"                = {}
    "Root2/Shared"         = {}
    "Root2/Shared/Network" = {}
  }
}

output "folder_ids" {
  description = "Map of folder path => folder id."
  value       = module.folders.folder_ids
}
