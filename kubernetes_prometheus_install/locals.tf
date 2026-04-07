locals {
  default_affinity = {
    nodeAffinity = {
      requiredDuringSchedulingIgnoredDuringExecution = {
        nodeSelectorTerms = [{
          matchExpressions = [{
            key      = "kubernetes.azure.com/mode"
            operator = "NotIn"
            values   = ["system"]
          }]
        }]
      }
    }
  }
}
