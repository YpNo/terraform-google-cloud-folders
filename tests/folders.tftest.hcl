# Unit tests for the depth-agnostic folder engine.
# Run with: terraform test
#
# A mocked google provider lets us validate path parsing, parent derivation and
# input validation entirely at plan time, with no real GCP credentials.

mock_provider "google" {
  mock_data "google_organization" {
    defaults = {
      org_id = "123456789"
    }
  }
}

variables {
  org_domain = "example.com"
}

# Deep, multi-root hierarchy: parsing, counts and parent derivation.
run "deep_multi_root_hierarchy" {
  command = plan

  variables {
    folders = {
      "Root1"                        = {}
      "Root1/Team A"                 = {}
      "Root1/Team A/Backend"         = {}
      "Root1/Team A/Backend/Service" = {}
      "Root2"                        = {}
      "Root2/Team B"                 = {}
    }
  }

  assert {
    condition     = length(output.folder_ids) == 6
    error_message = "Expected 6 folders to be planned."
  }

  assert {
    condition     = output.folders["Root1/Team A/Backend/Service"].display_name == "Service"
    error_message = "Display name must be the last path segment."
  }

  assert {
    condition     = length(google_folder.depth4) == 1 && length(google_folder.depth1) == 2
    error_message = "Folders must be bucketed into the correct depth-level resources."
  }

  assert {
    condition     = output.folder_parents["Root1/Team A/Backend/Service"] == "Root1/Team A/Backend"
    error_message = "Parent must be derived by trimming the last segment, at any depth."
  }

  assert {
    condition     = output.folder_parents["Root1"] == "organization"
    error_message = "Single-segment folders must be parented to the organization."
  }

  assert {
    condition     = output.folder_parents["Root2/Team B"] == "Root2"
    error_message = "Sibling roots must resolve their own subtree parents."
  }
}

# Full apply: proves the parent chain and the merged output resolve end-to-end,
# not just at plan time. deletion_protection is disabled so teardown succeeds.
run "apply_resolves_full_hierarchy" {
  command = apply

  variables {
    folders = {
      "Root1"                = { deletion_protection = false }
      "Root1/Team A"         = { deletion_protection = false }
      "Root1/Team A/Backend" = { deletion_protection = false }
    }
  }

  assert {
    condition     = length(output.folder_ids) == 3
    error_message = "All three folders should be created."
  }

  assert {
    condition     = can(output.folder_names["Root1/Team A/Backend"]) && output.folder_names["Root1/Team A/Backend"] != ""
    error_message = "Deepest folder must have a resolved resource name after apply."
  }

  assert {
    condition     = google_folder.depth3["Root1/Team A/Backend"].parent == google_folder.depth2["Root1/Team A"].name
    error_message = "A folder's parent must resolve to its immediate ancestor's resource name."
  }
}

# Global deletion settings apply by default and are overridable per folder.
run "global_deletion_settings_with_override" {
  command = plan

  variables {
    deletion_protection = false
    deletion_policy     = "ABANDON"
    folders = {
      "A" = {}                              # inherits both globals
      "B" = { deletion_protection = true }  # overrides protection only
      "C" = { deletion_policy = "PREVENT" } # overrides policy only
    }
  }

  assert {
    condition     = google_folder.depth1["A"].deletion_protection == false && google_folder.depth1["A"].deletion_policy == "ABANDON"
    error_message = "Folder A must inherit the module-level deletion defaults."
  }

  assert {
    condition     = google_folder.depth1["B"].deletion_protection == true && google_folder.depth1["B"].deletion_policy == "ABANDON"
    error_message = "Folder B must override deletion_protection while inheriting deletion_policy."
  }

  assert {
    condition     = google_folder.depth1["C"].deletion_protection == false && google_folder.depth1["C"].deletion_policy == "PREVENT"
    error_message = "Folder C must override deletion_policy while inheriting deletion_protection."
  }
}

# Empty input is valid and creates nothing.
run "empty_input_creates_nothing" {
  command = plan

  variables {
    folders = {}
  }

  assert {
    condition     = length(output.folder_ids) == 0
    error_message = "Empty folders map must produce no resources."
  }
}

# A nested folder whose parent path is absent must fail validation.
run "orphan_parent_rejected" {
  command = plan

  variables {
    folders = {
      "Root1"            = {}
      "Root1/A/Orphaned" = {} # parent "Root1/A" is missing
    }
  }

  expect_failures = [var.folders]
}

# Invalid display name (contains "/" is impossible, but >30 chars / bad chars).
run "invalid_display_name_rejected" {
  command = plan

  variables {
    folders = {
      "This name is definitely longer than thirty characters" = {}
    }
  }

  expect_failures = [var.folders]
}

# Exceeding GCP's 10-level nesting limit must fail.
run "max_depth_rejected" {
  command = plan

  variables {
    folders = {
      "L1"                                 = {}
      "L1/L2"                              = {}
      "L1/L2/L3"                           = {}
      "L1/L2/L3/L4"                        = {}
      "L1/L2/L3/L4/L5"                     = {}
      "L1/L2/L3/L4/L5/L6"                  = {}
      "L1/L2/L3/L4/L5/L6/L7"               = {}
      "L1/L2/L3/L4/L5/L6/L7/L8"            = {}
      "L1/L2/L3/L4/L5/L6/L7/L8/L9"         = {}
      "L1/L2/L3/L4/L5/L6/L7/L8/L9/L10"     = {}
      "L1/L2/L3/L4/L5/L6/L7/L8/L9/L10/L11" = {} # 11 levels
    }
  }

  expect_failures = [var.folders]
}

# Invalid deletion_policy must fail.
run "invalid_deletion_policy_rejected" {
  command = plan

  variables {
    folders = {
      "Root1" = { deletion_policy = "KEEP" }
    }
  }

  expect_failures = [var.folders]
}

# An explicit org_id is used verbatim and skips the google_organization lookup.
run "org_id_takes_precedence_and_skips_lookup" {
  command = plan

  variables {
    org_id     = "999888777"
    org_domain = null
    folders    = { "Root1" = {} }
  }

  assert {
    condition     = length(data.google_organization.this) == 0
    error_message = "The org lookup must be skipped when org_id is provided."
  }

  assert {
    condition     = google_folder.depth1["Root1"].parent == "organizations/999888777"
    error_message = "Root folders must be parented to the supplied org_id."
  }
}

# Without org_id, the domain lookup is used (mock returns 123456789).
run "org_domain_lookup_used_when_no_org_id" {
  command = plan

  variables {
    org_domain = "example.com"
    folders    = { "Root1" = {} }
  }

  assert {
    condition     = length(data.google_organization.this) == 1
    error_message = "The org lookup must run when org_id is not provided."
  }

  assert {
    condition     = google_folder.depth1["Root1"].parent == "organizations/123456789"
    error_message = "Root folders must be parented to the org id resolved from the domain."
  }
}

# Neither org_id nor org_domain set must fail with a clear message.
run "missing_org_inputs_rejected" {
  command = plan

  variables {
    org_id     = null
    org_domain = null
    folders    = { "Root1" = {} }
  }

  expect_failures = [data.google_organization.this]
}

# A malformed org_id (non-digits / with prefix) must fail validation.
run "invalid_org_id_rejected" {
  command = plan

  variables {
    org_id  = "organizations/123"
    folders = { "Root1" = {} }
  }

  expect_failures = [var.org_id]
}
