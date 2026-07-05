variable "folder" {
  type        = string
  description = "Folder to manage IAM for, in the form \"folders/<id>\" (e.g. \"folders/123456789\")."

  validation {
    condition     = can(regex("^folders/[0-9]+$", var.folder))
    error_message = "folder must be of the form \"folders/<id>\", e.g. \"folders/123456789\"."
  }
}

variable "members" {
  type        = map(set(string))
  default     = {}
  description = <<-EOT
    Non-authoritative (additive) IAM members, keyed by role. Each member is
    granted the role without removing other bindings on the folder
    (google_folder_iam_member). Example:

      {
        "roles/viewer" = ["user:alice@example.com", "group:team@example.com"]
      }
  EOT
}

variable "bindings" {
  type        = map(set(string))
  default     = {}
  description = <<-EOT
    Authoritative IAM bindings, keyed by role. For each role the given member
    set becomes the complete list (google_folder_iam_binding) — members granted
    that role outside Terraform are removed. Example:

      {
        "roles/resourcemanager.folderAdmin" = ["group:admins@example.com"]
      }
  EOT
}

variable "conditional_bindings" {
  type = list(object({
    role        = string
    members     = set(string)
    title       = string
    description = optional(string)
    expression  = string
  }))
  default     = []
  description = <<-EOT
    Authoritative IAM bindings that carry an IAM Condition. Each entry is a
    distinct google_folder_iam_binding identified by its role + condition title,
    so a role may appear here multiple times with different conditions. Example:

      [{
        role       = "roles/viewer"
        members    = ["user:alice@example.com"]
        title      = "expires_2026"
        expression = "request.time < timestamp(\"2026-12-31T00:00:00Z\")"
      }]
  EOT

  validation {
    condition     = length(var.conditional_bindings) == length(distinct([for b in var.conditional_bindings : "${b.role} ${b.title}"]))
    error_message = "Each conditional binding must have a unique role + title combination."
  }
}

variable "audit_configs" {
  type = map(object({
    audit_log_configs = set(object({
      log_type         = string
      exempted_members = optional(set(string), [])
    }))
  }))
  default     = {}
  description = <<-EOT
    Audit logging configuration keyed by service (e.g. "allServices"). Maps to
    google_folder_iam_audit_config. Example:

      {
        "allServices" = {
          audit_log_configs = [
            { log_type = "ADMIN_READ" },
            { log_type = "DATA_WRITE", exempted_members = ["user:svc@example.com"] },
          ]
        }
      }
  EOT

  validation {
    condition = alltrue([
      for cfg in values(var.audit_configs) : alltrue([
        for c in cfg.audit_log_configs : contains(["ADMIN_READ", "DATA_READ", "DATA_WRITE"], c.log_type)
      ])
    ])
    error_message = "audit_log_configs log_type must be one of ADMIN_READ, DATA_READ or DATA_WRITE."
  }
}

variable "policy_bindings" {
  type = list(object({
    role    = string
    members = set(string)
    condition = optional(object({
      title       = string
      description = optional(string)
      expression  = string
    }))
  }))
  default     = null
  description = <<-EOT
    Authoritative IAM policy for the whole folder (google_folder_iam_policy).
    When set, it REPLACES the entire folder policy and therefore must not be
    combined with members, bindings, conditional_bindings or audit_configs.
    Leave null to manage IAM additively/per-role instead.
  EOT
}
