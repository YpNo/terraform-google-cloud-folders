module "folders" {
  source = "../../"

  org_domain = "example.com"

  folders = {
    "Root1"                = {}
    "Root1/Team A"         = {}
    "Root1/Team A/Backend" = {}
  }
}

# Adopt pre-existing GCP folders into Terraform state instead of recreating them.
# Each folder must be imported into the module's depthN resource that matches its
# nesting level: depth1 = root, depth2 = one level down, depth3 = two levels down.

import {
  id = "folders/111111111"
  to = module.folders.google_folder.depth1["Root1"]
}

import {
  id = "folders/222222222"
  to = module.folders.google_folder.depth2["Root1/Team A"]
}

import {
  id = "folders/333333333"
  to = module.folders.google_folder.depth3["Root1/Team A/Backend"]
}

output "folder_ids" {
  description = "Map of folder path => folder id."
  value       = module.folders.folder_ids
}
