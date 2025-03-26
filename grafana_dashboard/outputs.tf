output "subfolder" {
  value = distinct(local.dashboard_subfolder_map)
}

output "folder" {
  value = distinct(local.dashboard_folder_map)
}