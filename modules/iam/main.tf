locals {
  # Flatten { role => members } into one entry per (role, member) pair, keyed by
  # "<role> <member>" (neither value can contain a space, so the key is unique).
  iam_members = merge([
    for role, members in var.members : {
      for member in members : "${role} ${member}" => {
        role   = role
        member = member
      }
    }
  ]...)

  # Conditional bindings keyed by role + condition title.
  conditional_bindings = {
    for b in var.conditional_bindings : "${b.role} ${b.title}" => b
  }

  manage_policy = var.policy_bindings != null
}

# Additive: grants a member a role without touching other bindings.
resource "google_folder_iam_member" "this" {
  for_each = local.iam_members

  folder = var.folder
  role   = each.value.role
  member = each.value.member
}

# Authoritative for the given role: the member set becomes exhaustive.
resource "google_folder_iam_binding" "authoritative" {
  for_each = var.bindings

  folder  = var.folder
  role    = each.key
  members = each.value
}

# Authoritative per role + condition.
resource "google_folder_iam_binding" "conditional" {
  for_each = local.conditional_bindings

  folder  = var.folder
  role    = each.value.role
  members = each.value.members

  condition {
    title       = each.value.title
    description = each.value.description
    expression  = each.value.expression
  }
}

# Audit logging configuration, one resource per service.
resource "google_folder_iam_audit_config" "this" {
  for_each = var.audit_configs

  folder  = var.folder
  service = each.key

  dynamic "audit_log_config" {
    for_each = each.value.audit_log_configs
    content {
      log_type         = audit_log_config.value.log_type
      exempted_members = audit_log_config.value.exempted_members
    }
  }
}

# Full authoritative policy. Mutually exclusive with the resources above.
data "google_iam_policy" "this" {
  count = local.manage_policy ? 1 : 0

  dynamic "binding" {
    for_each = var.policy_bindings
    content {
      role    = binding.value.role
      members = binding.value.members

      dynamic "condition" {
        for_each = binding.value.condition != null ? [binding.value.condition] : []
        content {
          title       = condition.value.title
          description = condition.value.description
          expression  = condition.value.expression
        }
      }
    }
  }
}

resource "google_folder_iam_policy" "this" {
  count = local.manage_policy ? 1 : 0

  folder      = var.folder
  policy_data = data.google_iam_policy.this[0].policy_data

  lifecycle {
    precondition {
      condition     = length(var.members) == 0 && length(var.bindings) == 0 && length(var.conditional_bindings) == 0 && length(var.audit_configs) == 0
      error_message = "policy_bindings is authoritative for the whole folder and cannot be combined with members, bindings, conditional_bindings or audit_configs."
    }
  }
}
