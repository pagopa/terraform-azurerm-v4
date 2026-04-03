locals {
  alert_name                = replace(var.alert_name != null ? lower("${var.alert_name}") : lower("${var.https_endpoint}"), (var.replace_non_words_in_name ? "/\\W/" : "-"), "-")
  alert_name_sha256_limited = substr(sha256(var.alert_name), 0, 5)
}
