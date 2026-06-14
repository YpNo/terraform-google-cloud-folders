output "folder_ids" {
  description = "Map of folder path => folder id (e.g. \"123456789\")."
  value       = { for path, folder in local.all_folders : path => folder.folder_id }
}

output "folder_names" {
  description = "Map of folder path => resource name (e.g. \"folders/123456789\")."
  value       = { for path, folder in local.all_folders : path => folder.name }
}

output "folder_parents" {
  description = "Map of folder path => parent path (\"organization\" for root folders). Derived from the input keys."
  value       = { for path, folder in local.folders : path => coalesce(folder.parent_key, "organization") }
}

output "folders" {
  description = "Full google_folder objects keyed by path."
  value       = local.all_folders
}
