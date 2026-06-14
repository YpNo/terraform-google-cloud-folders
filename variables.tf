variable "org_domain" {
  type        = string
  description = "The Organization domain, used to resolve the organization ID via the google_organization data source."
}

variable "deletion_protection" {
  type        = bool
  default     = true
  description = "Default for whether Terraform is prevented from destroying/recreating folders. Can be overridden per folder via folders[*].deletion_protection."
}

variable "deletion_policy" {
  type        = string
  default     = "DELETE"
  description = "Default deletion policy for folders. One of DELETE, PREVENT or ABANDON. Can be overridden per folder via folders[*].deletion_policy."

  validation {
    condition     = contains(["DELETE", "PREVENT", "ABANDON"], var.deletion_policy)
    error_message = "deletion_policy must be one of \"DELETE\", \"PREVENT\" or \"ABANDON\"."
  }
}

variable "folders" {
  description = <<-EOT
    Folder hierarchy as a flat map keyed by full path, using "/" as the separator.

    - The display name is the last path segment.
    - The parent is derived by trimming the last segment; a single-segment key
      is created directly under the organization.
    - Every parent path MUST also exist as a key in the map.

    Supports any nesting depth (up to GCP's 10-level folder limit) with no code
    changes. Example:

      {
        "Root1"                = {}
        "Root1/Team A"         = {}
        "Root1/Team A/Backend" = { deletion_protection = true }
        "Root2"                = {}
      }

    deletion_protection and deletion_policy are optional per folder; when unset
    (null) they inherit the module-level var.deletion_protection /
    var.deletion_policy defaults.
  EOT

  type = map(object({
    deletion_protection = optional(bool)
    deletion_policy     = optional(string)
    tags                = optional(map(string), {})
  }))

  default = {}

  # Every non-root folder must have its parent path present as a key.
  validation {
    condition = alltrue([
      for path in keys(var.folders) :
      length(split("/", path)) == 1 || contains(
        keys(var.folders),
        join("/", slice(split("/", path), 0, length(split("/", path)) - 1))
      )
    ])
    error_message = "Every nested folder must have its parent path present as a key in var.folders."
  }

  # Display name (last segment) must follow GCP rules: start/end alphanumeric,
  # allow letters, digits, spaces, hyphens and underscores, max 30 characters.
  validation {
    condition = alltrue([
      for path in keys(var.folders) :
      can(regex("^[\\p{L}\\p{N}]([\\p{L}\\p{N} _-]{0,28}[\\p{L}\\p{N}])?$", element(split("/", path), length(split("/", path)) - 1)))
    ])
    error_message = "Each folder display name (last path segment) must start and end with a letter or digit, contain only letters, digits, spaces, hyphens or underscores, and be at most 30 characters."
  }

  # Enforce GCP's maximum folder nesting depth of 10 levels.
  validation {
    condition = alltrue([
      for path in keys(var.folders) : length(split("/", path)) <= 10
    ])
    error_message = "GCP supports a maximum of 10 nested folder levels; one or more paths exceed this limit."
  }

  # A per-folder deletion_policy override, when set, must be a valid value.
  # A conditional (not ||) guarantees contains() never receives null, which
  # errors on Terraform versions that don't short-circuit || during validation.
  validation {
    condition = alltrue([
      for cfg in values(var.folders) :
      cfg.deletion_policy == null ? true : contains(["DELETE", "PREVENT", "ABANDON"], cfg.deletion_policy)
    ])
    error_message = "Per-folder deletion_policy override must be one of \"DELETE\", \"PREVENT\" or \"ABANDON\"."
  }
}
