# Folder IAM submodule

Manage IAM for a **single** Google Cloud folder. Standalone and composable: use
it directly with a `folder` id, or let the root module fan it out across many
folders. Covers every `google_folder_iam_*` resource kind.

## Modes

| Variable               | Resource                          | Authoritative? |
| ---------------------- | --------------------------------- | -------------- |
| `members`              | `google_folder_iam_member`        | No (additive)  |
| `bindings`             | `google_folder_iam_binding`       | Yes, per role  |
| `conditional_bindings` | `google_folder_iam_binding`       | Yes, per role + condition |
| `audit_configs`        | `google_folder_iam_audit_config`  | Yes, per service |
| `policy_bindings`      | `google_folder_iam_policy`        | Yes, whole folder |

`policy_bindings` replaces the entire folder policy, so it cannot be combined
with any of the other inputs (enforced by a precondition). The other inputs can
be freely mixed.

## Usage

```hcl
module "folder_iam" {
  source = "github.com/YpNo/terraform-google-cloud-folders//modules/iam"

  folder = "folders/123456789"

  # Additive — leaves other bindings intact.
  members = {
    "roles/viewer" = ["user:alice@example.com", "group:team@example.com"]
  }

  # Authoritative for the role.
  bindings = {
    "roles/resourcemanager.folderAdmin" = ["group:admins@example.com"]
  }

  # Authoritative with an IAM Condition.
  conditional_bindings = [{
    role       = "roles/viewer"
    members    = ["user:contractor@example.com"]
    title      = "expires_2026"
    expression = "request.time < timestamp(\"2026-12-31T00:00:00Z\")"
  }]

  # Audit logging.
  audit_configs = {
    "allServices" = {
      audit_log_configs = [
        { log_type = "ADMIN_READ" },
        { log_type = "DATA_WRITE", exempted_members = ["user:svc@example.com"] },
      ]
    }
  }
}
```

<details>
<summary>Authoritative full policy (mutually exclusive with the above)</summary>

```hcl
module "folder_iam" {
  source = "github.com/YpNo/terraform-google-cloud-folders//modules/iam"

  folder = "folders/123456789"

  policy_bindings = [
    { role = "roles/resourcemanager.folderAdmin", members = ["group:admins@example.com"] },
    { role = "roles/viewer", members = ["group:readers@example.com"] },
  ]
}
```

</details>

## Testing

```bash
terraform init -backend=false && terraform test
```

Tests use a mocked google provider (no credentials) and cover each IAM mode plus
every validation path.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.15.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.15.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_folder_iam_audit_config.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_audit_config) | resource |
| [google_folder_iam_binding.authoritative](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_binding) | resource |
| [google_folder_iam_binding.conditional](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_binding) | resource |
| [google_folder_iam_member.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_member) | resource |
| [google_folder_iam_policy.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_policy) | resource |
| [google_iam_policy.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_audit_configs"></a> [audit\_configs](#input\_audit\_configs) | Audit logging configuration keyed by service (e.g. "allServices"). Maps to<br/>google\_folder\_iam\_audit\_config. Example:<br/><br/>  {<br/>    "allServices" = {<br/>      audit\_log\_configs = [<br/>        { log\_type = "ADMIN\_READ" },<br/>        { log\_type = "DATA\_WRITE", exempted\_members = ["user:svc@example.com"] },<br/>      ]<br/>    }<br/>  } | <pre>map(object({<br/>    audit_log_configs = set(object({<br/>      log_type         = string<br/>      exempted_members = optional(set(string), [])<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_bindings"></a> [bindings](#input\_bindings) | Authoritative IAM bindings, keyed by role. For each role the given member<br/>set becomes the complete list (google\_folder\_iam\_binding) — members granted<br/>that role outside Terraform are removed. Example:<br/><br/>  {<br/>    "roles/resourcemanager.folderAdmin" = ["group:admins@example.com"]<br/>  } | `map(set(string))` | `{}` | no |
| <a name="input_conditional_bindings"></a> [conditional\_bindings](#input\_conditional\_bindings) | Authoritative IAM bindings that carry an IAM Condition. Each entry is a<br/>distinct google\_folder\_iam\_binding identified by its role + condition title,<br/>so a role may appear here multiple times with different conditions. Example:<br/><br/>  [{<br/>    role       = "roles/viewer"<br/>    members    = ["user:alice@example.com"]<br/>    title      = "expires\_2026"<br/>    expression = "request.time < timestamp(\"2026-12-31T00:00:00Z\")"<br/>  }] | <pre>list(object({<br/>    role        = string<br/>    members     = set(string)<br/>    title       = string<br/>    description = optional(string)<br/>    expression  = string<br/>  }))</pre> | `[]` | no |
| <a name="input_folder"></a> [folder](#input\_folder) | Folder to manage IAM for, in the form "folders/<id>" (e.g. "folders/123456789"). | `string` | n/a | yes |
| <a name="input_members"></a> [members](#input\_members) | Non-authoritative (additive) IAM members, keyed by role. Each member is<br/>granted the role without removing other bindings on the folder<br/>(google\_folder\_iam\_member). Example:<br/><br/>  {<br/>    "roles/viewer" = ["user:alice@example.com", "group:team@example.com"]<br/>  } | `map(set(string))` | `{}` | no |
| <a name="input_policy_bindings"></a> [policy\_bindings](#input\_policy\_bindings) | Authoritative IAM policy for the whole folder (google\_folder\_iam\_policy).<br/>When set, it REPLACES the entire folder policy and therefore must not be<br/>combined with members, bindings, conditional\_bindings or audit\_configs.<br/>Leave null to manage IAM additively/per-role instead. | <pre>list(object({<br/>    role    = string<br/>    members = set(string)<br/>    condition = optional(object({<br/>      title       = string<br/>      description = optional(string)<br/>      expression  = string<br/>    }))<br/>  }))</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_audit_config_etags"></a> [audit\_config\_etags](#output\_audit\_config\_etags) | Map of service => etag for audit configs. |
| <a name="output_binding_etags"></a> [binding\_etags](#output\_binding\_etags) | Map of role => etag for authoritative bindings. |
| <a name="output_conditional_binding_etags"></a> [conditional\_binding\_etags](#output\_conditional\_binding\_etags) | Map of "<role> <title>" => etag for conditional bindings. |
| <a name="output_folder"></a> [folder](#output\_folder) | The folder these IAM settings apply to. |
| <a name="output_member_etags"></a> [member\_etags](#output\_member\_etags) | Map of "<role> <member>" => etag for additive members. |
| <a name="output_policy_etag"></a> [policy\_etag](#output\_policy\_etag) | Etag of the authoritative folder policy, or null when policy\_bindings is unused. |
<!-- END_TF_DOCS -->
