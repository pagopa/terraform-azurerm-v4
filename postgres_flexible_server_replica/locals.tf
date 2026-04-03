locals {
  default_main_server_metrics = {
    replication_delay_bytes = {
      frequency        = "PT5M"
      window_size      = "PT30M"
      metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
      aggregation      = "Average"
      metric_name      = "physical_replication_delay_in_bytes"
      operator         = "GreaterThanOrEqual"
      threshold        = 240
      severity         = 2
    }
  }
  default_replica_server_metrics = {
    replica_lag = {
      frequency        = "PT5M"
      window_size      = "PT30M"
      metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
      aggregation      = "Average"
      metric_name      = "physical_replication_delay_in_seconds"
      operator         = "GreaterThanOrEqual"
      threshold        = 240
      severity         = 2
    }
  }
}
