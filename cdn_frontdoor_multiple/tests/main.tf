locals {
  prefix      = var.prefix
  location    = var.location
  dns_zone    = "devopslab.pagopa.it"
  dns_zone_rg = "dvopla-d-itn-vnet-rg"
  environment = "test"
}

data "azurerm_client_config" "current" {}

############################################################
# Resource Group
############################################################
resource "azurerm_resource_group" "test" {
  name     = "${local.prefix}-rg"
  location = local.location

  tags = merge(var.tags, {
    Environment = local.environment
  })
}

############################################################
# Log Analytics Workspace (for diagnostics)
############################################################
resource "azurerm_log_analytics_workspace" "test" {
  name                = "${local.prefix}-law"
  location            = local.location
  resource_group_name = azurerm_resource_group.test.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = merge(var.tags, {
    Environment = local.environment
  })
}

############################################################
# CDN Front Door with Storage Account
############################################################
module "cdn" {
  source = "../"

  resource_group_name        = azurerm_resource_group.test.name
  location                   = local.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.test.id
  tenant_id                  = data.azurerm_client_config.current.tenant_id

  # CDN Profile
  profile = {
    name = "${local.prefix}-cdn"
  }

  # Create storage account for static website.
  # Setting 'origin_group' wires the static website automatically as a CDN
  # origin of that group (no need to feed outputs back into inputs).
  storage_account = {
    enabled                  = true
    account_name             = "${local.prefix}testsa"
    account_replication_type = "ZRS"
    index_document           = "index.html"
    error_404_document       = "error.html"
    origin_group             = "web-pool"
  }

  # Endpoints (entry points for CDN)
  endpoints = {
    "web" = {
      name = "${local.prefix}-cdn-web"
    }
    "api" = {
      name = "${local.prefix}-cdn-api"
    }
  }

  # Origins (backend servers).
  # The static-website storage origin is injected automatically by the module
  # (see storage_account.origin_group), so it must NOT be declared here.
  origins = {
    "api-backend" = {
      host_name  = "example.com"
      https_port = 443
      http_port  = 80
      priority   = 1
      weight     = 1000
    }
  }

  # Origin Groups (pools of backends with health checks)
  origin_groups = {
    "web-pool" = {
      description = "Primary web/static content pool (served by the auto-injected static-website storage origin)"
      members     = []

      health_probe = {
        path                = "/"
        protocol            = "Https"
        request_type        = "GET"
        interval_in_seconds = 120
      }

      load_balancing = {
        sample_size                        = 4
        successful_samples_required        = 2
        additional_latency_in_milliseconds = 0
      }
    }

    "api-pool" = {
      description = "API backend pool"
      members     = ["api-backend"]

      health_probe = {
        path                = "/"
        protocol            = "Https"
        request_type        = "GET"
        interval_in_seconds = 60
      }
    }
  }

  # Routes (connect endpoints to origin groups)
  routes = {
    "web-default" = {
      endpoint       = "web"
      origin_group   = "web-pool"
      patterns       = ["/*"]
      protocols      = ["Http", "Https"]
      forwarding     = "MatchRequest"
      https_redirect = true
      cache_behavior = "IgnoreQueryString"
      custom_domains = [
        "www.${local.dns_zone}"
      ]
      rulesets = ["WebSecurity", "WebCaching"]
      enabled  = true
    }

    "api-route" = {
      endpoint       = "api"
      origin_group   = "api-pool"
      patterns       = ["/api/*"]
      protocols      = ["Http", "Https"]
      forwarding     = "MatchRequest"
      https_redirect = true
      cache_behavior = "UseQueryString"
      custom_domains = ["api2.${local.dns_zone}"]
      rulesets       = ["ApiSecurity"]
      enabled        = true
    }
  }

  # Rulesets with Rules
  rulesets = {
    "WebSecurity" = {
      description = "Security rules for web endpoint"

      rules = {
        "Https" = {
          order             = 10
          behavior_on_match = "Continue"

          condition = {
            type         = "request_scheme"
            operator     = "Equal"
            match_values = ["HTTP"]
          }

          actions = [{
            type          = "redirect"
            redirect_type = "PermanentRedirect"
            protocol      = "Https"
            hostname      = local.dns_zone
          }]
        }

        "SecurityHeaders" = {
          order             = 20
          behavior_on_match = "Continue"
          conditions        = [] # Apply to all requests

          actions = [
            {
              type          = "response_header"
              header_action = "Append"
              header_name   = "Strict-Transport-Security"
              value         = "max-age=31536000; includeSubDomains"
            },
            {
              type          = "response_header"
              header_action = "Append"
              header_name   = "X-Content-Type-Options"
              value         = "nosniff"
            },
            {
              type          = "response_header"
              header_action = "Append"
              header_name   = "X-Frame-Options"
              value         = "DENY"
            },
            {
              type          = "response_header"
              header_action = "Append"
              header_name   = "X-XSS-Protection"
              value         = "1; mode=block"
            }
          ]
        }
      }
    }

    "WebCaching" = {
      description = "Caching rules for web endpoint"

      rules = {
        "CacheForever" = {
          order             = 10
          behavior_on_match = "Continue"

          condition = {
            type         = "url_file_extension"
            operator     = "Equal"
            match_values = ["js", "css", "jpg", "jpeg", "png", "gif", "svg", "woff", "woff2", "ico"]
          }

          actions = [{
            type                  = "cache"
            behavior              = "Override"
            duration              = "365.00:00:00"
            query_string_behavior = "UseQueryString"
          }]
        }

        "CacheHtml" = {
          order             = 20
          behavior_on_match = "Continue"

          condition = {
            type         = "url_file_extension"
            operator     = "Equal"
            match_values = ["html"]
          }

          actions = [{
            type                  = "cache"
            behavior              = "Override"
            duration              = "1.00:00:00"
            query_string_behavior = "UseQueryString"
          }]
        }

        "NoCacheRoot" = {
          order             = 30
          behavior_on_match = "Continue"

          condition = {
            type         = "request_uri"
            operator     = "Equal"
            match_values = ["/"]
          }

          actions = [{
            type     = "cache"
            behavior = "Disabled"
          }]
        }
      }
    }

    "ApiSecurity" = {
      description = "Security rules for API endpoint"

      rules = {
        "ApiForceHttps" = {
          order             = 10
          behavior_on_match = "Continue"

          condition = {
            type         = "request_scheme"
            operator     = "Equal"
            match_values = ["HTTP"]
          }

          actions = [{
            type          = "redirect"
            redirect_type = "PermanentRedirect"
            protocol      = "Https"
            hostname      = "api2.${local.dns_zone}"
          }]
        }

        "ApiCorsHeaders" = {
          order             = 20
          behavior_on_match = "Continue"
          conditions        = []

          actions = [
            {
              type          = "response_header"
              header_action = "Append"
              header_name   = "Access-Control-Allow-Origin"
              value         = "*"
            },
            {
              type          = "response_header"
              header_action = "Append"
              header_name   = "Access-Control-Allow-Methods"
              value         = "GET, POST, PUT, DELETE, OPTIONS"
            }
          ]
        }

        "ApiNoCache" = {
          order             = 30
          behavior_on_match = "Continue"
          conditions        = []

          actions = [{
            type     = "cache"
            behavior = "Disabled"
          }]
        }
      }
    }
  }

  # Custom domains (your own domain names)
  custom_domains = {
    "www.${local.dns_zone}" = {
      dns_zone_name                = local.dns_zone
      dns_zone_resource_group_name = local.dns_zone_rg
      certificate_type             = "ManagedCertificate"
      enable_dns_records           = true
      ttl                          = 300
    }

    "api2.${local.dns_zone}" = {
      dns_zone_name                = local.dns_zone
      dns_zone_resource_group_name = local.dns_zone_rg
      certificate_type             = "ManagedCertificate"
      enable_dns_records           = true
      ttl                          = 300
    }
  }
}