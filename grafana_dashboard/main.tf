provider "grafana" {
  alias = "cloud"

  url  = var.grafana_url
  auth = var.grafana_api_key
}

locals {
  allowed_resource_by_file = fileset("${path.module}/${var.dashboard_directory_path}", "*.json")
  allowed_resource_type_replaced = [
    for item in local.allowed_resource_by_file :
    replace(item, "_", "/")
  ]
  allowed_resource_type = [
    for item in local.allowed_resource_type_replaced :
    trimsuffix(item, ".json")
  ]


}

data "azurerm_resources" "sub_resources" {
  for_each = toset(local.allowed_resource_type)
  type     = each.key

  required_tags = {
    grafana = "yes"
  }
}


locals {
  dashboard_folder_map = flatten([
    for rt in data.azurerm_resources.sub_resources : [
      for d in rt.resources : {
        domain_exists = lookup(d.tags, "domain", "nodomain")
      }
    ]
  ])

  dashboard_subfolder_map = flatten([
    for rt in data.azurerm_resources.sub_resources : [
      for d in rt.resources : {
        subdomain_exists = format("%s-%s",lookup(d.tags, "domain", "nodomain"),split("/", d.type)[1])
        //type = split("/", d.type)[1]
      }
    ]
  ])

  dashboard_resource_map = flatten([
    for rt in data.azurerm_resources.sub_resources : [
      for d in rt.resources : {
        type          = d.type
        name          = d.name
        rgroup        = d.resource_group_name
        sub           = split("/", d.id)[0]
        domain_exists = lookup(d.tags, "domain", "nodomain")
      }
    ]
  ])

}

resource "grafana_folder" "domainsfolderexist" {
  provider = grafana.cloud
  for_each = { for i in range(length(distinct(local.dashboard_folder_map))) : local.dashboard_folder_map[i].domain_exists => i }

  title = "${upper(var.prefix)}-${upper(local.dashboard_folder_map[each.value].domain_exists)}"
}

resource "grafana_folder" "domainsfolder" {
  provider = grafana.cloud
  for_each = { for i in range(length(distinct(local.dashboard_subfolder_map))) : local.dashboard_subfolder_map[i].subdomain_exists => i }

  parent_folder_uid = grafana_folder.domainsfolderexist["${split("-",local.dashboard_subfolder_map[each.value].subdomain_exists)[0]}"].uid
  title = "${upper(split("-",local.dashboard_subfolder_map[each.value].subdomain_exists)[0])}-${split("-",local.dashboard_subfolder_map[each.value].subdomain_exists)[1]}"
}


# resource "grafana_folder" "domainsfolder" {
#   provider          = grafana.cloud
#   for_each          = { for i in range(length(local.dashboard_resource_map)) : distinct(format("%s-%s", local.dashboard_resource_map[i].domain_exists, local.dashboard_resource_map[i].type)) => i }
#   parent_folder_uid = grafana_folder.domainsfolderexist["${local.dashboard_resource_map[each.value].domain_exists}"].uid

#   title = "${upper(local.dashboard_resource_map[each.value].domain_exists)}-${split("/", local.dashboard_resource_map[each.value].type)[1]}"
# }


resource "grafana_dashboard" "azure_monitor_grafana" {
  provider = grafana.cloud
  for_each = { for i in range(length(local.dashboard_resource_map)) : local.dashboard_resource_map[i].name => i }

  config_json = templatefile(
    "${path.module}/${var.dashboard_directory_path}/${replace(local.dashboard_resource_map[each.value].type, "/", "_")}.json",
    {
      resource  = "${local.dashboard_resource_map[each.value].name}"
      rg        = "${local.dashboard_resource_map[each.value].rgroup}"
      sub       = "${local.dashboard_resource_map[each.value].sub}"
      ds        = "Azure Monitor"
      prefix    = "${var.prefix}"
      workspace = "${var.monitor_workspace_id}"
    }
  )
  folder    = grafana_folder.domainsfolder["${local.dashboard_resource_map[each.value].domain_exists}-${local.dashboard_resource_map[each.value].type}"].id
  overwrite = true
}