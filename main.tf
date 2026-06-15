# Only look the organization up by domain when an explicit org_id wasn't given.
data "google_organization" "this" {
  count  = var.org_id == null ? 1 : 0
  domain = var.org_domain

  lifecycle {
    precondition {
      condition     = var.org_domain != null
      error_message = "Provide either var.org_id or var.org_domain (org_domain is required when org_id is unset)."
    }
  }
}

locals {
  # Prefer the explicit org_id; otherwise use the one resolved from the domain.
  org_id = var.org_id != null ? "organizations/${var.org_id}" : "organizations/${one(data.google_organization.this).org_id}"

  # Normalize each "/"-separated key into display name, parent path and depth,
  # and resolve effective deletion settings (per-folder override, else global).
  # parent_key is null for root folders (created directly under the org).
  folders = {
    for path, cfg in var.folders : path => {
      display_name        = element(split("/", path), length(split("/", path)) - 1)
      parent_key          = length(split("/", path)) == 1 ? null : join("/", slice(split("/", path), 0, length(split("/", path)) - 1))
      depth               = length(split("/", path))
      deletion_protection = cfg.deletion_protection != null ? cfg.deletion_protection : var.deletion_protection
      deletion_policy     = cfg.deletion_policy != null ? cfg.deletion_policy : var.deletion_policy
      tags                = cfg.tags
    }
  }

  # Bucket folders by depth (1..10). A depth-N folder's parent is always a
  # depth-(N-1) folder, so each level only ever references the one above it.
  depths = { for d in range(1, 11) : d => { for k, v in local.folders : k => v if v.depth == d } }
}

# Terraform cannot express recursion: a single resource referencing its own
# other for_each instances forms a graph cycle, and modules cannot self-call.
# We therefore materialize one block per depth level (GCP's hard limit is 10).
# This is an implementation detail only — consumers add depth purely via data.

resource "google_folder" "depth1" {
  for_each = local.depths[1]

  display_name        = each.value.display_name
  deletion_protection = each.value.deletion_protection
  deletion_policy     = each.value.deletion_policy
  tags                = each.value.tags
  parent              = local.org_id
}

resource "google_folder" "depth2" {
  for_each = local.depths[2]

  display_name        = each.value.display_name
  deletion_protection = each.value.deletion_protection
  deletion_policy     = each.value.deletion_policy
  tags                = each.value.tags
  parent              = google_folder.depth1[each.value.parent_key].name
}

resource "google_folder" "depth3" {
  for_each = local.depths[3]

  display_name        = each.value.display_name
  deletion_protection = each.value.deletion_protection
  deletion_policy     = each.value.deletion_policy
  tags                = each.value.tags
  parent              = google_folder.depth2[each.value.parent_key].name
}

resource "google_folder" "depth4" {
  for_each = local.depths[4]

  display_name        = each.value.display_name
  deletion_protection = each.value.deletion_protection
  deletion_policy     = each.value.deletion_policy
  tags                = each.value.tags
  parent              = google_folder.depth3[each.value.parent_key].name
}

resource "google_folder" "depth5" {
  for_each = local.depths[5]

  display_name        = each.value.display_name
  deletion_protection = each.value.deletion_protection
  deletion_policy     = each.value.deletion_policy
  tags                = each.value.tags
  parent              = google_folder.depth4[each.value.parent_key].name
}

resource "google_folder" "depth6" {
  for_each = local.depths[6]

  display_name        = each.value.display_name
  deletion_protection = each.value.deletion_protection
  deletion_policy     = each.value.deletion_policy
  tags                = each.value.tags
  parent              = google_folder.depth5[each.value.parent_key].name
}

resource "google_folder" "depth7" {
  for_each = local.depths[7]

  display_name        = each.value.display_name
  deletion_protection = each.value.deletion_protection
  deletion_policy     = each.value.deletion_policy
  tags                = each.value.tags
  parent              = google_folder.depth6[each.value.parent_key].name
}

resource "google_folder" "depth8" {
  for_each = local.depths[8]

  display_name        = each.value.display_name
  deletion_protection = each.value.deletion_protection
  deletion_policy     = each.value.deletion_policy
  tags                = each.value.tags
  parent              = google_folder.depth7[each.value.parent_key].name
}

resource "google_folder" "depth9" {
  for_each = local.depths[9]

  display_name        = each.value.display_name
  deletion_protection = each.value.deletion_protection
  deletion_policy     = each.value.deletion_policy
  tags                = each.value.tags
  parent              = google_folder.depth8[each.value.parent_key].name
}

resource "google_folder" "depth10" {
  for_each = local.depths[10]

  display_name        = each.value.display_name
  deletion_protection = each.value.deletion_protection
  deletion_policy     = each.value.deletion_policy
  tags                = each.value.tags
  parent              = google_folder.depth9[each.value.parent_key].name
}

locals {
  # Single flat view of every created folder, keyed by path, for outputs.
  all_folders = merge(
    google_folder.depth1,
    google_folder.depth2,
    google_folder.depth3,
    google_folder.depth4,
    google_folder.depth5,
    google_folder.depth6,
    google_folder.depth7,
    google_folder.depth8,
    google_folder.depth9,
    google_folder.depth10,
  )
}
