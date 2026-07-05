output "folder" {
  description = "The folder these IAM settings apply to."
  value       = var.folder
}

output "member_etags" {
  description = "Map of \"<role> <member>\" => etag for additive members."
  value       = { for k, m in google_folder_iam_member.this : k => m.etag }
}

output "binding_etags" {
  description = "Map of role => etag for authoritative bindings."
  value       = { for role, b in google_folder_iam_binding.authoritative : role => b.etag }
}

output "conditional_binding_etags" {
  description = "Map of \"<role> <title>\" => etag for conditional bindings."
  value       = { for k, b in google_folder_iam_binding.conditional : k => b.etag }
}

output "audit_config_etags" {
  description = "Map of service => etag for audit configs."
  value       = { for svc, c in google_folder_iam_audit_config.this : svc => c.etag }
}

output "policy_etag" {
  description = "Etag of the authoritative folder policy, or null when policy_bindings is unused."
  value       = one(google_folder_iam_policy.this[*].etag)
}
