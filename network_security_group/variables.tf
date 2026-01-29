variable "prefix" {
  type        = string
  description = "Prefix for all resources"
}


variable "resource_group_name" {
  description = "Name of the resource group where the nsg will be saved"
  type        = string
}

variable "location" {
  description = "Location of the resource group where the nsg will be saved"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to the nsg"
  type        = map(string)
}

variable "custom_security_group" {
  description = "security groups configuration"
  type = map(object({
    target_subnet_name      = optional(string, null)
    target_subnet_vnet_name = optional(string, null)
    target_subnet_id        = optional(string, null) # optional target subnet id. overrides the pair <target_subnet_name, target_subnet_vnet_name>. useful when subnet not yet created
    target_subnet_cidr      = optional(string, null) # optional, instead of using the pair <target_subnet_name, target_subnet_vnet_name>. useful when subnet not yet created
    watcher_enabled         = optional(bool, false)
    inbound_rules = list(object({
      name                         = string
      priority                     = number
      target_service               = optional(string, null)
      access                       = optional(string, "Allow")
      protocol                     = optional(string)
      source_subnet_name           = optional(string)
      source_subnet_vnet_name      = optional(string)
      source_port_ranges           = optional(list(string), ["*"])
      source_address_prefixes      = optional(list(string), [])
      destination_address_prefixes = optional(list(string), [])
      destination_port_ranges      = optional(list(string), ["*"])
      description                  = optional(string)
    }))

    outbound_rules = list(object({
      name                         = string
      priority                     = number
      target_service               = optional(string, null)
      access                       = optional(string, "Allow")
      protocol                     = optional(string)
      source_address_prefixes      = optional(list(string), [])
      source_port_ranges           = optional(list(string), ["*"])
      destination_subnet_name      = optional(string)
      destination_subnet_vnet_name = optional(string)
      destination_port_ranges      = optional(list(string), ["*"])
      destination_address_prefixes = optional(list(string), [])
      description                  = optional(string)
    }))
  }))
  default = null

  validation {
    condition = var.custom_security_group == null ? true : alltrue([
      for nsg in var.custom_security_group : (
        length(distinct([for rule in nsg.inbound_rules : rule.name])) == length(nsg.inbound_rules)
      )
    ])
    error_message = "inbound_rules: rule name must be unique within the security group."
  }

  validation {
    condition = var.custom_security_group == null ? true : alltrue([
      for nsg in var.custom_security_group : (
        length(distinct([for rule in nsg.outbound_rules : rule.name])) == length(nsg.outbound_rules)
      )
    ])
    error_message = "outbound_rules: rule name must be unique within the security group."
  }

  validation {
    condition = var.custom_security_group == null ? true : alltrue(flatten([
      [
        for nsg in var.custom_security_group : [
          nsg.target_subnet_id != null ? nsg.target_subnet_name == null && nsg.target_subnet_vnet_name == null : nsg.target_subnet_name != null && nsg.target_subnet_vnet_name != null
        ]
      ]
    ]))
    error_message = "target_subnet_id and (target_subnet_name, target_subnet_vnet_name) are mutually exclusive"
  }

  validation {
    condition = var.custom_security_group == null ? true : alltrue(flatten([
      [
        for nsg in var.custom_security_group : [
          (nsg.target_subnet_id != null && nsg.target_subnet_cidr != null) || (nsg.target_subnet_id == null && nsg.target_subnet_cidr == null)
        ]
      ]
    ]))
    error_message = "target_subnet_id and target_subnet_cidr must be both defined or both null"
  }

  validation {
    condition = var.custom_security_group == null ? true : alltrue(flatten([
      [
        for nsg in var.custom_security_group : [
          [for rule in nsg.inbound_rules : (rule.description == null ? true : length(rule.description) <= 140)],
          [for rule in nsg.outbound_rules : (rule.description == null ? true : length(rule.description) <= 140)]
        ]
      ]
    ]))
    error_message = "description must be shorter than 140 characters."
  }

  validation {
    condition = var.custom_security_group == null ? true : alltrue(flatten(
      [
        for nsg in var.custom_security_group : [
          for rule in concat(nsg.inbound_rules, nsg.outbound_rules) : (
            length(rule.source_address_prefixes) == 0 ||                                                                                               # vuoto
            (length(rule.source_address_prefixes) == 1 && alltrue([for p in rule.source_address_prefixes : (p == "*")])) ||                            # solo "*"
            (length(rule.source_address_prefixes) == 1 && alltrue([for p in rule.source_address_prefixes : (length(regexall("[A-Za-z]", p)) > 0)])) || # solo un elemento "servicetag"
            alltrue([for prefix in rule.source_address_prefixes : can(regex("^(\\d{1,3}\\.){3}\\d{1,3}(/\\d{1,2})?$", prefix))])                       # lista di IP/CIDR validi
          )
        ]
    ]))
    error_message = "source_address_prefixes must be: empty, or contain only '*', or a single servicetag element, or a list of valid IP/CIDR."
  }

  validation {
    condition = var.custom_security_group == null ? true : alltrue(flatten(
      [
        for nsg in var.custom_security_group : [
          for rule in concat(nsg.inbound_rules, nsg.outbound_rules) : (
            length(rule.destination_address_prefixes) == 0 ||                                                                                                    # vuoto
            (length(rule.destination_address_prefixes) == 1 && alltrue([for p in rule.destination_address_prefixes : (p == "*")])) ||                            # solo "*"
            (length(rule.destination_address_prefixes) == 1 && alltrue([for p in rule.destination_address_prefixes : (length(regexall("[A-Za-z]", p)) > 0)])) || # solo un elemento "servicetag"
            alltrue([for prefix in rule.destination_address_prefixes : can(regex("^(\\d{1,3}\\.){3}\\d{1,3}(/\\d{1,2})?$", prefix))])                            # lista di IP/CIDR validi
          )
        ]
    ]))
    error_message = "destination_address_prefixes must be: empty, or contain only '*', or a single servicetag element, or a list of valid IP/CIDR."
  }

  validation {
    condition = var.custom_security_group == null ? true : alltrue(flatten(
      [
        for nsg in var.custom_security_group : [
          for rule in concat(nsg.inbound_rules, nsg.outbound_rules) : (
            length(rule.source_port_ranges) == 0 ||                                                               # vuoto
            (length(rule.source_port_ranges) == 1 && alltrue([for p in rule.source_port_ranges : (p == "*")])) || # solo "*"
            alltrue([for port in rule.source_port_ranges : can(regex("^\\d+(-\\d+)?$", port))])                   # lista di porte/range validi
          )
        ]
    ]))
    error_message = "source_port_ranges must be: empty, or contain only '*', or a list of ports (e.g., '80') or port ranges (e.g., '1024-2048')."
  }

  validation {
    condition = var.custom_security_group == null ? true : alltrue(flatten(
      [
        for nsg in var.custom_security_group : [
          for rule in concat(nsg.inbound_rules, nsg.outbound_rules) : (
            length(rule.destination_port_ranges) == 0 ||                                                                    # vuoto
            (length(rule.destination_port_ranges) == 1 && alltrue([for p in rule.destination_port_ranges : (p == "*")])) || # solo "*"
            alltrue([for port in rule.destination_port_ranges : can(regex("^\\d+(-\\d+)?$", port))])                        # lista di porte/range validi
          )
        ]
    ]))
    error_message = "destination_port_ranges must be: empty, or contain only '*', or a list of ports (e.g., '80') or port ranges (e.g., '1024-2048')."
  }




  validation {
    condition = var.custom_security_group == null ? true : alltrue([
      for nsg in var.custom_security_group : (
        length(distinct([for rule in nsg.inbound_rules : rule.priority])) == length(nsg.inbound_rules)
      )
    ])
    error_message = "inbound_rules: priority must be unique."
  }

  validation {
    condition = var.custom_security_group == null ? true : alltrue([
      for nsg in var.custom_security_group : (
        length(distinct([for rule in nsg.outbound_rules : rule.priority])) == length(nsg.outbound_rules)
      )
    ])
    error_message = "outbound_rules: priority must be unique."
  }


  validation {
    condition = var.custom_security_group == null ? true : alltrue(flatten([
      for nsg in var.custom_security_group : (
        [
          for rule in nsg.outbound_rules : ((rule.priority <= 4096) && (rule.priority >= 100))
        ]
      )
      ])
    )
    error_message = "outbound_rules: priority must be between 100 and 4096"
  }

  validation {
    condition = var.custom_security_group == null ? true : alltrue(flatten([
      for nsg in var.custom_security_group : (
        [
          for rule in nsg.inbound_rules : ((rule.priority <= 4096) && (rule.priority >= 100))
        ]
      )
      ])
    )
    error_message = "inbound_rules: priority must be between 100 and 4096"
  }


  validation {
    condition = var.custom_security_group == null ? true : alltrue(flatten([
      for nsg in var.custom_security_group : (
        [
          for rule in nsg.outbound_rules : (rule.priority % 10 == 0)
        ]
      )
      ])
    )
    error_message = "outbound_rules: priority must be divisible by 10"
  }

  validation {
    condition = var.custom_security_group == null ? true : alltrue(flatten([
      for nsg in var.custom_security_group : (
        [
          for rule in nsg.inbound_rules : (rule.priority % 10 == 0)
        ]
      )
      ])
    )
    error_message = "inbound_rules: priority must be divisible by 10"
  }


  validation {
    condition = var.custom_security_group == null ? true : alltrue(flatten([
      for nsg in var.custom_security_group : [
        for rule in concat(nsg.inbound_rules, nsg.outbound_rules) : (
          contains(["Allow", "Deny"], rule.access)
        )
      ]
    ]))
    error_message = "Access must be either 'Allow' or 'Deny'."
  }


  validation {
    condition = var.custom_security_group == null ? true : alltrue(flatten([
      for nsg in var.custom_security_group : [
        for rule in nsg.outbound_rules : (
          (rule.destination_subnet_name != null && length(rule.destination_address_prefixes) == 0) ||
          (rule.destination_subnet_name == null && length(rule.destination_address_prefixes) > 0)
        )
      ]
    ]))
    error_message = "outbound_rules: destination_subnet_name and destination_address_prefixes are mutually exclusive"
  }

  validation {
    condition = var.custom_security_group == null ? true : alltrue(flatten([
      for nsg in var.custom_security_group : [
        for rule in nsg.inbound_rules : (
          (rule.source_subnet_name != null && length(rule.source_address_prefixes) == 0) ||
          (rule.source_subnet_name == null && length(rule.source_address_prefixes) > 0)
        )
      ]
    ]))
    error_message = "inbound_rules: source_subnet_name and source_address_prefixes are mutually exclusive"
  }

  validation {
    condition = var.custom_security_group == null ? true : alltrue(flatten([
      for nsg in var.custom_security_group : [
        for rule in nsg.outbound_rules : (
          (rule.destination_subnet_name != null && rule.destination_subnet_vnet_name != null) ||
          (rule.destination_subnet_name == null && rule.destination_subnet_vnet_name == null)
        )
      ]
    ]))
    error_message = "outbound_rules: destination_subnet_name and destination_subnet_vnet_name must both be defined or both be null"
  }

  validation {
    condition = var.custom_security_group == null ? true : alltrue(flatten([
      for nsg in var.custom_security_group : [
        for rule in nsg.inbound_rules : (
          (rule.source_subnet_name != null && rule.source_subnet_vnet_name != null) ||
          (rule.source_subnet_name == null && rule.source_subnet_vnet_name == null)
        )
      ]
    ]))
    error_message = "inbound_rules: source_subnet_name and source_subnet_vnet_name must both be defined or both be null"
  }

  validation {
    condition = var.custom_security_group == null ? true : alltrue(flatten([
      for nsg in var.custom_security_group : [
        for rule in concat(nsg.inbound_rules, nsg.outbound_rules) : (
          (rule.target_service == null &&
            rule.protocol != null) || (
            rule.target_service != null &&
            rule.protocol == null &&
            contains(rule.destination_port_ranges, "*") # default value
          )
        )
      ]
    ]))
    error_message = "inbound and outbound rules: target_service and the pair <protocol, destination_port_ranges> are mutually exclusive"
  }

  validation {
    condition = var.custom_security_group == null ? true : alltrue(flatten([
      for nsg in var.custom_security_group : [
        for rule in concat(nsg.inbound_rules, nsg.outbound_rules) : (
          rule.target_service == null ? true : contains(keys(local.target_services), rule.target_service)
        )
      ]
    ]))
    error_message = "inbound and outbound rules: target_service must be one of ${join(",", keys(local.target_services))}"
  }


  validation {
    condition = var.custom_security_group == null ? true : alltrue(flatten([
      for nsg in var.custom_security_group : [
        for rule in concat(nsg.inbound_rules, nsg.outbound_rules) : (
          rule.protocol != null ? contains(["Tcp", "Udp", "Icmp", "Esp", "Ah", "*"], title(rule.protocol)) : rule.target_service != null
        )
      ]
    ]))
    error_message = "inbound and outbound rules: protocol must be one of ['Tcp', 'Udp', 'Icmp', 'Esp', 'Ah', '*'] or target_service must be used"
  }
}



variable "vnets" {
  type        = map(string)
  description = "(Required) Map of virtual networks names and their resource groups where the involved (target, source, destination) subnets are located"
}


variable "flow_logs" {
  type = object({
    network_watcher_name                   = string
    network_watcher_rg                     = string
    storage_account_id                     = string
    retention_days                         = optional(number, 2)
    traffic_analytics_law_name             = string
    traffic_analytics_law_rg               = string
    traffic_analytics_law_interval_minutes = optional(number, 10)
  })
  default     = null
  description = "(Optional) Parameters required to configure the network watcher"
}

variable "enabled_only_rules" {
  type = object({
    enabled             = bool
    security_group_name = optional(string, null)
  })
  description = "(Optional) Enables a 'rules-only' mode. If 'enabled' is set to true, the module skips the creation of the NSG, association, and flow logs"

  default = {
    enabled             = false
    security_group_name = null
  }

  validation {
    condition     = var.enabled_only_rules.enabled ? var.enabled_only_rules.security_group_name != null : true
    error_message = "When 'enabled_only_rules.enabled' is true, a valid 'security_group_name' must be provided."
  }
}