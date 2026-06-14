# Changelog

## [0.1.0] (unreleased)

* Replace the nested `folders_map` variable with a flat, path-keyed `folders`
  map supporting arbitrary nesting depth (up to GCP's 10-level limit) with no
  module edits.
* Drop the `terraform-google-modules/folders/google` wrapper submodule in favour
  of native `google_folder` resources. To adopt existing folders, import them by
  ID (see the README).
* Outputs replaced: `root_folder_ids` / `level1_folder_ids` / `level2_folder_ids`
  are removed in favour of path-keyed `folder_ids`, `folder_names`,
  `folder_parents` and `folders`.
* Provider requirement raised to `google >= 5.0.0` (for `deletion_protection`
  and `deletion_policy`).

### Features

* Module-level `deletion_protection` and `deletion_policy` defaults, overridable
  per folder; plus per-folder `tags`.
* Plan-time validation: orphaned parents, invalid display names, excessive depth
  and invalid `deletion_policy` are rejected.
* `terraform test` suite with a mocked google provider (no credentials needed).
