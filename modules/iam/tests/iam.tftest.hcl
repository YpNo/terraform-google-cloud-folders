# Unit tests for the folder IAM submodule.
# Run from modules/iam with: terraform test
#
# A mocked google provider lets us validate wiring and input validation entirely
# at plan time, with no real GCP credentials.

mock_provider "google" {
  # google_folder_iam_policy parses policy_data as JSON at plan time, so the
  # mocked data source must return valid JSON rather than a random string.
  mock_data "google_iam_policy" {
    defaults = {
      policy_data = "{\"bindings\":[]}"
    }
  }
}

variables {
  folder = "folders/123456789"
}

# Additive members: one google_folder_iam_member per (role, member) pair.
run "members_create_one_resource_per_pair" {
  command = plan

  variables {
    members = {
      "roles/viewer" = ["user:alice@example.com", "group:team@example.com"]
      "roles/editor" = ["user:bob@example.com"]
    }
  }

  assert {
    condition     = length(google_folder_iam_member.this) == 3
    error_message = "Expected one member resource per (role, member) pair."
  }

  assert {
    condition     = google_folder_iam_member.this["roles/editor user:bob@example.com"].role == "roles/editor"
    error_message = "Member resources must be keyed by \"<role> <member>\"."
  }
}

# Authoritative bindings: one resource per role.
run "bindings_are_authoritative_per_role" {
  command = plan

  variables {
    bindings = {
      "roles/resourcemanager.folderAdmin" = ["group:admins@example.com"]
      "roles/viewer"                      = ["user:alice@example.com"]
    }
  }

  assert {
    condition     = length(google_folder_iam_binding.authoritative) == 2
    error_message = "Expected one authoritative binding per role."
  }

  assert {
    condition     = google_folder_iam_binding.authoritative["roles/viewer"].folder == "folders/123456789"
    error_message = "Bindings must target the supplied folder."
  }
}

# Conditional bindings keyed by role + title.
run "conditional_bindings_keyed_by_role_and_title" {
  command = plan

  variables {
    conditional_bindings = [{
      role       = "roles/viewer"
      members    = ["user:alice@example.com"]
      title      = "expires_2026"
      expression = "request.time < timestamp(\"2026-12-31T00:00:00Z\")"
    }]
  }

  assert {
    condition     = length(google_folder_iam_binding.conditional) == 1
    error_message = "Expected one conditional binding resource."
  }
}

# Audit configs: one resource per service.
run "audit_configs_per_service" {
  command = plan

  variables {
    audit_configs = {
      "allServices" = {
        audit_log_configs = [
          { log_type = "ADMIN_READ" },
          { log_type = "DATA_WRITE", exempted_members = ["user:svc@example.com"] },
        ]
      }
    }
  }

  assert {
    condition     = length(google_folder_iam_audit_config.this) == 1
    error_message = "Expected one audit config per service."
  }
}

# Authoritative full policy creates the policy resource (and skips it otherwise).
run "policy_bindings_create_policy_resource" {
  command = plan

  variables {
    policy_bindings = [
      { role = "roles/resourcemanager.folderAdmin", members = ["group:admins@example.com"] },
    ]
  }

  assert {
    condition     = length(google_folder_iam_policy.this) == 1
    error_message = "policy_bindings must produce a google_folder_iam_policy."
  }
}

# No inputs: nothing is created.
run "empty_inputs_create_nothing" {
  command = plan

  assert {
    condition     = length(google_folder_iam_member.this) == 0 && length(google_folder_iam_binding.authoritative) == 0 && length(google_folder_iam_policy.this) == 0
    error_message = "With no IAM inputs the module must create no resources."
  }
}

# A malformed folder reference must fail validation.
run "invalid_folder_rejected" {
  command = plan

  variables {
    folder = "123456789" # missing "folders/" prefix
  }

  expect_failures = [var.folder]
}

# An invalid audit log_type must fail validation.
run "invalid_audit_log_type_rejected" {
  command = plan

  variables {
    audit_configs = {
      "allServices" = { audit_log_configs = [{ log_type = "EVERYTHING" }] }
    }
  }

  expect_failures = [var.audit_configs]
}

# Duplicate role + title in conditional bindings must fail validation.
run "duplicate_conditional_binding_rejected" {
  command = plan

  variables {
    conditional_bindings = [
      { role = "roles/viewer", members = ["user:a@example.com"], title = "t", expression = "true" },
      { role = "roles/viewer", members = ["user:b@example.com"], title = "t", expression = "false" },
    ]
  }

  expect_failures = [var.conditional_bindings]
}

# Authoritative policy must not be combined with additive/per-role inputs.
run "policy_conflicts_with_other_inputs" {
  command = plan

  variables {
    policy_bindings = [{ role = "roles/owner", members = ["user:a@example.com"] }]
    bindings        = { "roles/viewer" = ["user:b@example.com"] }
  }

  expect_failures = [google_folder_iam_policy.this]
}
