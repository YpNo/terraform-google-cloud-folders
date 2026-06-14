# Google Cloud Folders Module

[![CI](https://github.com/YpNo/terraform-google-cloud-folders/actions/workflows/ci.yml/badge.svg)](https://github.com/YpNo/terraform-google-cloud-folders/actions/workflows/ci.yml)
[![Latest Release](https://img.shields.io/github/v/release/YpNo/terraform-google-cloud-folders?sort=semver&logo=github)](https://github.com/YpNo/terraform-google-cloud-folders/releases)
[![Terraform Registry](https://img.shields.io/badge/terraform-registry-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/modules/YpNo/cloud-folders/google/latest)
[![Terraform](https://img.shields.io/badge/terraform-%3E%3D_1.7.0-7B42BC?logo=terraform&logoColor=white)](https://developer.hashicorp.com/terraform/install)
[![Provider](https://img.shields.io/badge/google-%3E%3D_5.0-4285F4?logo=googlecloud&logoColor=white)](https://registry.terraform.io/providers/hashicorp/google/latest)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-FAB040?logo=pre-commit&logoColor=white)](https://pre-commit.com/)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Manage a Google Cloud **folder hierarchy of any depth** under an Organization
from a single, flat map — declare folders by path, never edit the module to add
a level.

```hcl
folders = {
  "Root1"                = {}
  "Root1/Team A"         = {}
  "Root1/Team A/Backend" = {} # nest as deep as you like (GCP allows 10 levels)
  "Root2"                = {}
}
```

The key is the full path (`/`-separated): the **display name** is the last
segment and the **parent** is everything before it (a single segment lands under
the organization). Parents may be declared in any order.

## How it works

Terraform can't recurse — a resource that references its own `for_each`
instances forms a cycle, and modules can't self-call. So the module declares one
`google_folder` block per depth (1–10, GCP's hard limit); each level references
only the one above it, keeping the graph acyclic. It's an internal detail — you
only ever supply data.

## Usage

```hcl
module "folders" {
  source  = "github.com/YpNo/terraform-google-cloud-folders"
  version = "0.1.1"

  org_domain = "example.com"

  # Defaults for every folder; override per folder as needed.
  deletion_protection = true
  deletion_policy     = "DELETE"

  folders = {
    "Root1"                = {}
    "Root1/Team A"         = {}
    "Root1/Team A/Backend" = { deletion_protection = false } # override
    "Root2"                = {}
    "Root2/Shared/Network" = {}
    "Root2/Shared"         = {}
  }
}
```

<details>
<summary>With Terragrunt</summary>

```hcl
terraform {
  source = "github.com/YpNo/terraform-google-cloud-folders.git?ref=v0.1.1"
}

inputs = {
  org_domain = "example.com"
  folders    = { "Root1" = {}, "Root1/Team A" = {} }
}
```

</details>

## Per-folder overrides

Each `folders` value takes optional fields. `deletion_protection` and
`deletion_policy` are `null` by default and **inherit** the module-level
`var.deletion_protection` / `var.deletion_policy`; set them to override.

| Field                 | Type          | Default         | Notes                                                  |
| --------------------- | ------------- | --------------- | ------------------------------------------------------ |
| `deletion_protection` | `bool`        | inherits global | Block destroy/recreate of this folder.                 |
| `deletion_policy`     | `string`      | inherits global | `DELETE`, `PREVENT` or `ABANDON`.                      |
| `tags`                | `map(string)` | `{}`            | Resource-manager tags (`tagKeys/x` => `tagValues/y`). |

## Validation

`folders` is rejected at plan time when a path's parent is missing, a display
name is empty / >30 chars / has illegal characters, nesting exceeds 10 levels,
or a `deletion_policy` is invalid.

## Importing existing folders

Import pre-existing folders by their (stable) IDs into the `depthN` resource that
matches each folder's level (`depth1` = root, `depth2` = one level down, …). Note
the address differs: when you call this as a module the resources are nested
under it, whereas Terragrunt runs the module *as the root* so they are top-level.

**With Terraform** — add `import` blocks alongside the `module` call:

```hcl
import {
  id = "folders/111111111"
  to = module.folders.google_folder.depth1["Root1"]
}
```

**With Terragrunt** — generate the `import` blocks into the unit (addresses have
no `module.` prefix):

```hcl
generate "imports" {
  path      = "imports.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    import {
      id = "folders/111111111"
      to = google_folder.depth1["Root1"]
    }
  EOF
}
```

Then run `terraform plan` / `terragrunt plan` and confirm **no destroys** before
applying. Full example: [`examples/with-import`](examples/with-import).

## Reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 5.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | >= 5.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_folder.depth1](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder) | resource |
| [google_folder.depth10](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder) | resource |
| [google_folder.depth2](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder) | resource |
| [google_folder.depth3](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder) | resource |
| [google_folder.depth4](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder) | resource |
| [google_folder.depth5](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder) | resource |
| [google_folder.depth6](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder) | resource |
| [google_folder.depth7](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder) | resource |
| [google_folder.depth8](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder) | resource |
| [google_folder.depth9](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder) | resource |
| [google_organization.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/organization) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_deletion_policy"></a> [deletion\_policy](#input\_deletion\_policy) | Default deletion policy for folders. One of DELETE, PREVENT or ABANDON. Can be overridden per folder via folders[*].deletion\_policy. | `string` | `"DELETE"` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Default for whether Terraform is prevented from destroying/recreating folders. Can be overridden per folder via folders[*].deletion\_protection. | `bool` | `true` | no |
| <a name="input_folders"></a> [folders](#input\_folders) | Folder hierarchy as a flat map keyed by full path, using "/" as the separator.<br/><br/>- The display name is the last path segment.<br/>- The parent is derived by trimming the last segment; a single-segment key<br/>  is created directly under the organization.<br/>- Every parent path MUST also exist as a key in the map.<br/><br/>Supports any nesting depth (up to GCP's 10-level folder limit) with no code<br/>changes. Example:<br/><br/>  {<br/>    "Root1"                = {}<br/>    "Root1/Team A"         = {}<br/>    "Root1/Team A/Backend" = { deletion\_protection = true }<br/>    "Root2"                = {}<br/>  }<br/><br/>deletion\_protection and deletion\_policy are optional per folder; when unset<br/>(null) they inherit the module-level var.deletion\_protection /<br/>var.deletion\_policy defaults. | <pre>map(object({<br/>    deletion_protection = optional(bool)<br/>    deletion_policy     = optional(string)<br/>    tags                = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_org_domain"></a> [org\_domain](#input\_org\_domain) | The Organization domain, used to resolve the organization ID via the google\_organization data source. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_folder_ids"></a> [folder\_ids](#output\_folder\_ids) | Map of folder path => folder id (e.g. "123456789"). |
| <a name="output_folder_names"></a> [folder\_names](#output\_folder\_names) | Map of folder path => resource name (e.g. "folders/123456789"). |
| <a name="output_folder_parents"></a> [folder\_parents](#output\_folder\_parents) | Map of folder path => parent path ("organization" for root folders). Derived from the input keys. |
| <a name="output_folders"></a> [folders](#output\_folders) | Full google\_folder objects keyed by path. |
<!-- END_TF_DOCS -->

## Testing

```bash
terraform init -backend=false && terraform test
```

Tests use a mocked google provider (no credentials) and cover deep hierarchies,
parent derivation, override resolution and every validation path.

## License

This module is licensed under the **Apache License 2.0** — see the
[LICENSE](LICENSE) and [NOTICE](NOTICE) files for details.

```
Copyright 2026 - YpNo

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
