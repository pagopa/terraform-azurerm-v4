locals {

  ## Postgres FQDN to Port mapping for ADF proxy
  postgres_fqdn_port_map = flatten([
    for db in var.database_adf_proxy_mapping : {
      db_map = "${db.fqdn};${db.external_port};${db.destination_port}"
    }
  ])

  ## Postgres FQDN list for Key Vault secret
  postgres_fqdn_map = flatten([
    for db in var.database_adf_proxy_mapping : {
      db_fqdn = "${db.fqdn}"
    }
  ])

  ## Generate script for port forwarding
  postgres_forward_port_script = templatefile("${path.module}/network_proxy_forward.sh.tpl", {
    env = substr(var.env, 0, 1) #env short
    db_map = join(",", local.postgres_fqdn_port_map[*].db_map) }
  )

  ## Script to enable IP Forwarding on VMSS
  ipfwd_script = file("${path.module}/create_ip_fwd.sh")


  ## Merge all scripts
  script_merge = "${local.ipfwd_script}${local.postgres_forward_port_script}"
  ## Base64 encode the merged script
  base64_script = base64encode(local.script_merge)

  database_map = join(",", local.postgres_fqdn_map[*].db_fqdn)
}
