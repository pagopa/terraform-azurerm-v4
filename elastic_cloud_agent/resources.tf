resource "kubectl_manifest" "agent_namespace" {
  count     = var.create_namespace ? 1 : 0
  yaml_body = (replace(replace(templatefile("${path.module}/yaml/namespace.yaml", local.template_resolution_variables), "/(?s:\nstatus:.*)$/", ""), "0640", "416"))

}

resource "kubectl_manifest" "config_map" {
  depends_on = [kubectl_manifest.agent_namespace]
  yaml_body  = (replace(replace(templatefile("${path.module}/yaml/configMap.yaml", local.template_resolution_variables), "/(?s:\nstatus:.*)$/", ""), "0640", "416"))

}

resource "kubectl_manifest" "cluster_role_binding" {
  depends_on = [kubectl_manifest.config_map]
  yaml_body  = (replace(replace(templatefile("${path.module}/yaml/clusterRoleBinding.yaml", local.template_resolution_variables), "/(?s:\nstatus:.*)$/", ""), "0640", "416"))

}

resource "kubectl_manifest" "elastic_agent_role_binding" {
  depends_on = [kubectl_manifest.cluster_role_binding]
  yaml_body  = (replace(replace(templatefile("${path.module}/yaml/elasticAgentRoleBinding.yaml", local.template_resolution_variables), "/(?s:\nstatus:.*)$/", ""), "0640", "416"))

}

resource "kubectl_manifest" "elastic_agent_kubeadmin_role_binding" {
  depends_on = [kubectl_manifest.elastic_agent_role_binding]
  yaml_body  = (replace(replace(templatefile("${path.module}/yaml/elasticAgentKubeAdminRoleBinding.yaml", local.template_resolution_variables), "/(?s:\nstatus:.*)$/", ""), "0640", "416"))

}

resource "kubectl_manifest" "cluster_role" {
  depends_on = [kubectl_manifest.elastic_agent_kubeadmin_role_binding]
  yaml_body  = (replace(replace(templatefile("${path.module}/yaml/clusterRole.yaml", local.template_resolution_variables), "/(?s:\nstatus:.*)$/", ""), "0640", "416"))

}

resource "kubectl_manifest" "elastic_agent_role" {
  depends_on = [kubectl_manifest.cluster_role]
  yaml_body  = (replace(replace(templatefile("${path.module}/yaml/elasticAgentRole.yaml", local.template_resolution_variables), "/(?s:\nstatus:.*)$/", ""), "0640", "416"))

}

resource "kubectl_manifest" "elastic_agent_kubeadmin_role" {
  depends_on = [kubectl_manifest.elastic_agent_role]
  yaml_body  = (replace(replace(templatefile("${path.module}/yaml/elasticAgentKubeAdminRole.yaml", local.template_resolution_variables), "/(?s:\nstatus:.*)$/", ""), "0640", "416"))

}

resource "kubectl_manifest" "service_account" {
  depends_on = [kubectl_manifest.elastic_agent_kubeadmin_role]
  yaml_body  = (replace(replace(templatefile("${path.module}/yaml/serviceAccount.yaml", local.template_resolution_variables), "/(?s:\nstatus:.*)$/", ""), "0640", "416"))

}

resource "kubectl_manifest" "secret_api_key" {
  depends_on = [kubectl_manifest.service_account]
  yaml_body  = (replace(replace(templatefile("${path.module}/yaml/secret.yaml", local.template_resolution_variables), "/(?s:\nstatus:.*)$/", ""), "0640", "416"))

}

resource "kubectl_manifest" "daemon_set" {
  depends_on = [kubectl_manifest.secret_api_key]
  yaml_body  = (replace(replace(templatefile("${path.module}/yaml/daemonSet.yaml", local.template_resolution_variables), "/(?s:\nstatus:.*)$/", ""), "0640", "416"))

}