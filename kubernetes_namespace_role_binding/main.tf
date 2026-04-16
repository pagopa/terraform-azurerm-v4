resource "kubernetes_namespace" "this" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.name
  }
}

data "kubernetes_namespace" "this" {
  count = var.create_namespace ? 0 : 1
  metadata {
    name = var.name
  }
}

resource "kubernetes_role_binding" "group_edit" {
  for_each = toset(var.ad_group_ids)

  metadata {
    name      = "ad-group-edit-binding-${each.key}"
    namespace = var.create_namespace ? kubernetes_namespace.this[0].metadata[0].name : data.kubernetes_namespace.this[0].metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "edit"
  }

  subject {
    kind      = "Group"
    name      = each.key
    api_group = "rbac.authorization.k8s.io"
  }
}
