locals {
  # Define the target services and their respective port ranges and protocols
  target_services = {
    postgresql = [{
      port_ranges = ["5432", "6432"]
      protocol    = "tcp"
    }]
    redis = [
      {
        port_ranges = ["6379", "6380", "8443", "8500", "10221-10231", "13000-13999", "15000-15999", "16001", "20226"]
        protocol    = "tcp"
      },
      {
        port_ranges = ["8500", "16001"]
        protocol    = "udp"
      }
    ]
    cosmos = [{
      port_ranges = ["443", "10255", "10256"]
      protocol    = "tcp"
    }]
    eventhub = [{
      port_ranges = ["5671-5672", "443", "9093"]
      protocol    = "tcp"
    }]
    storage = [{
      port_ranges = ["443"]
      protocol    = "tcp"
    }]
  }


  subnet_names = toset(flatten([
    for csg in var.custom_security_group : [concat(
      [for ir in csg.inbound_rules :
        {
          name      = ir.source_subnet_name
          vnet_name = ir.source_subnet_vnet_name
          rg_name   = var.vnets[ir.source_subnet_vnet_name]
        }
      if ir.source_subnet_name != null],
      [for or in csg.outbound_rules :
        {
          name      = or.destination_subnet_name
          vnet_name = or.destination_subnet_vnet_name
          rg_name   = var.vnets[or.destination_subnet_vnet_name]
        }
      if or.destination_subnet_name != null],
      csg.target_subnet_vnet_name != null ? [
        {
          name      = csg.target_subnet_name
          vnet_name = csg.target_subnet_vnet_name
          rg_name   = var.vnets[csg.target_subnet_vnet_name]
        }
      ] : []
      )
    ]
  ]))

  security_rules = flatten(concat(
    [
      for key, nsg in var.custom_security_group :
      concat([
        # user defined inbound rules
        for rule in nsg.inbound_rules : concat(rule.target_service == null ? [
          {
            name               = rule.name
            priority           = rule.priority
            access             = rule.access
            protocol           = rule.protocol
            source_port_ranges = contains(rule.source_port_ranges, "*") ? null : rule.source_port_ranges
            source_port_range  = contains(rule.source_port_ranges, "*") ? "*" : null

            # Defines the source address prefixes for security rule:
            # - If source_address_prefixes list is empty:
            #   - Use subnet's address prefixes from source subnet
            # - If source_address_prefixes contains elements:
            #   - If all prefixes are numeric (no letters), use them as is
            #     - If any prefix contains letters/asterisk:
            #       - Use "*" if present in the list
            #   - Otherwise use the first prefix
            source_address_prefixes = length(rule.source_address_prefixes) == 0 ? data.azurerm_subnet.subnet["${rule.source_subnet_name}-${rule.source_subnet_vnet_name}"].address_prefixes : (alltrue([for p in rule.source_address_prefixes : (length(regexall("[A-Za-z\\*]", p)) == 0)]) ? rule.source_address_prefixes : null)
            source_address_prefix   = length(rule.source_address_prefixes) > 0 && (anytrue([for p in rule.source_address_prefixes : (length(regexall("[A-Za-z\\*]", p)) > 0)])) ? (contains(rule.source_address_prefixes, "*") ? "*" : rule.source_address_prefixes[0]) : null

            destination_port_ranges = contains(rule.destination_port_ranges, "*") ? null : rule.destination_port_ranges
            destination_port_range  = contains(rule.destination_port_ranges, "*") ? "*" : null

            # Defines the destination address prefixes for security rule:
            # - If destination_address_prefixes list is empty:
            #   - Use subnet's address prefixes from target subnet
            # - If destination_address_prefixes contains elements:
            #   - If all prefixes are numeric (no letters), use them as is
            #   - If any prefix contains letters/asterisk:
            #     - Use "*" if present in the list
            #     - Otherwise use the first prefix
            destination_address_prefixes = length(rule.destination_address_prefixes) == 0 ? (nsg.target_subnet_id != null ? [nsg.target_subnet_cidr] : data.azurerm_subnet.subnet["${nsg.target_subnet_name}-${nsg.target_subnet_vnet_name}"].address_prefixes) : (alltrue([for p in rule.destination_address_prefixes : (length(regexall("[A-Za-z]", p)) == 0)]) ? rule.destination_address_prefixes : null)
            destination_address_prefix   = length(rule.destination_address_prefixes) > 0 && (anytrue([for p in rule.destination_address_prefixes : (length(regexall("[A-Za-z\\*]", p)) > 0)])) ? (contains(rule.destination_address_prefixes, "*") ? "*" : rule.destination_address_prefixes[0]) : null


            nsg_name  = key
            direction = "Inbound"
          }
          ] : [
          for i, ts_definition in local.target_services[rule.target_service] : {
            name               = "${rule.name}-${i}"
            priority           = rule.priority + i
            access             = rule.access
            protocol           = rule.target_service != null ? title(ts_definition.protocol) : rule.protocol
            source_port_ranges = contains(rule.source_port_ranges, "*") ? null : rule.source_port_ranges
            source_port_range  = contains(rule.source_port_ranges, "*") ? "*" : null

            # Defines the source address prefixes for security rule:
            # - If source_address_prefixes list is empty:
            #   - Use subnet's address prefixes from source subnet
            # - If source_address_prefixes contains elements:
            #   - If all prefixes are numeric (no letters), use them as is
            #     - If any prefix contains letters/asterisk:
            #       - Use "*" if present in the list
            #   - Otherwise use the first prefix
            source_address_prefixes = length(rule.source_address_prefixes) == 0 ? data.azurerm_subnet.subnet["${rule.source_subnet_name}-${rule.source_subnet_vnet_name}"].address_prefixes : (alltrue([for p in rule.source_address_prefixes : (length(regexall("[A-Za-z\\*]", p)) == 0)]) ? rule.source_address_prefixes : null)
            source_address_prefix   = length(rule.source_address_prefixes) > 0 && (anytrue([for p in rule.source_address_prefixes : (length(regexall("[A-Za-z\\*]", p)) > 0)])) ? (contains(rule.source_address_prefixes, "*") ? "*" : rule.source_address_prefixes[0]) : null

            destination_port_ranges = rule.target_service != null ? ts_definition.port_ranges : (contains(rule.destination_port_ranges, "*") ? null : rule.destination_port_ranges)
            destination_port_range  = rule.target_service != null ? null : (contains(rule.destination_port_ranges, "*") ? "*" : null)

            # Defines the destination address prefixes for security rule:
            # - If destination_address_prefixes list is empty:
            #   - Use subnet's address prefixes from target subnet
            # - If destination_address_prefixes contains elements:
            #   - If all prefixes are numeric (no letters), use them as is
            #   - If any prefix contains letters/asterisk:
            #     - Use "*" if present in the list
            #     - Otherwise use the first prefix
            destination_address_prefixes = length(rule.destination_address_prefixes) == 0 ? (nsg.target_subnet_id != null ? [nsg.target_subnet_cidr] : data.azurerm_subnet.subnet["${nsg.target_subnet_name}-${nsg.target_subnet_vnet_name}"].address_prefixes) : (alltrue([for p in rule.destination_address_prefixes : (length(regexall("[A-Za-z]", p)) == 0)]) ? rule.destination_address_prefixes : null)
            destination_address_prefix   = length(rule.destination_address_prefixes) > 0 && (anytrue([for p in rule.destination_address_prefixes : (length(regexall("[A-Za-z\\*]", p)) > 0)])) ? (contains(rule.destination_address_prefixes, "*") ? "*" : rule.destination_address_prefixes[0]) : null


            nsg_name  = key
            direction = "Inbound"
          }
        ])
        ],
        # Generates "Self-Inbound" rules to allow intra-subnet traffic for each defined rule.
        # 1. Flattens all inbound rules to handle multi-protocol target services
        # 2. Assigns sequential priorities starting from 4080 (4080 + idx) to guarantee uniqueness without overlaps
        # 3. Appends the protocol to the rule name to avoid duplicate names
        [
          for key, nsg in var.custom_security_group : [
            for idx, entry in flatten([
              for rule in nsg.inbound_rules : [
                for definitions in [rule.target_service != null ? local.target_services[rule.target_service] : [{
                  protocol    = rule.protocol
                  port_ranges = length(rule.destination_port_ranges) > 0 ? rule.destination_port_ranges : (rule.destination_port_range != null ? [rule.destination_port_range] : ["*"])
                  }]] : [
                  for i, def in definitions : {
                    rule = rule
                    def  = def
                  }
                ]
              ]
              ]) : {
              name     = "${entry.rule.name}Self${title(entry.def.protocol)}"
              priority = 4080 + idx

              direction = "Inbound"
              access    = "Allow"
              protocol  = title(entry.def.protocol)
              nsg_name  = key

              source_port_range  = "*"
              source_port_ranges = null

              source_address_prefix   = null
              source_address_prefixes = nsg.target_subnet_id != null ? [nsg.target_subnet_cidr] : data.azurerm_subnet.subnet["${nsg.target_subnet_name}-${nsg.target_subnet_vnet_name}"].address_prefixes

              destination_address_prefix   = null
              destination_address_prefixes = nsg.target_subnet_id != null ? [nsg.target_subnet_cidr] : data.azurerm_subnet.subnet["${nsg.target_subnet_name}-${nsg.target_subnet_vnet_name}"].address_prefixes

              destination_port_ranges = !contains(entry.def.port_ranges, "*") && length(entry.def.port_ranges) > 1 ? entry.def.port_ranges : null
              destination_port_range  = contains(entry.def.port_ranges, "*") ? "*" : (length(entry.def.port_ranges) == 1 ? entry.def.port_ranges[0] : null)
            }
          ]
      ])
    ],
    [
      for key, nsg in var.custom_security_group :
      concat([
        # user defined outbound rules
        for rule in nsg.outbound_rules : concat(rule.target_service == null ? [
          {
            name                    = rule.name
            priority                = rule.priority
            access                  = rule.access
            protocol                = rule.protocol
            source_port_ranges      = contains(rule.source_port_ranges, "*") ? null : rule.source_port_ranges
            source_port_range       = contains(rule.source_port_ranges, "*") ? "*" : null
            destination_port_ranges = contains(rule.destination_port_ranges, "*") ? null : rule.destination_port_ranges
            destination_port_range  = contains(rule.destination_port_ranges, "*") ? "*" : null


            # Defines the source address prefixes for outbound security rule:
            # - If source_address_prefixes list is empty:
            #   - Use subnet's address prefixes from target subnet
            # - If source_address_prefixes contains elements:
            #   - If all prefixes are numeric (no letters), use them as is
            #     - If any prefix contains letters/asterisk:
            #       - Use "*" if present in the list
            #     - Otherwise use the first prefix
            source_address_prefixes = length(rule.source_address_prefixes) == 0 ? (nsg.target_subnet_id != null ? [nsg.target_subnet_cidr] : data.azurerm_subnet.subnet["${nsg.target_subnet_name}-${nsg.target_subnet_vnet_name}"].address_prefixes) : (alltrue([for p in rule.source_address_prefixes : (length(regexall("[A-Za-z]", p)) == 0)]) ? rule.source_address_prefixes : null)
            source_address_prefix   = length(rule.source_address_prefixes) > 0 && (anytrue([for p in rule.source_address_prefixes : (length(regexall("[A-Za-z\\*]", p)) > 0)])) ? (contains(rule.source_address_prefixes, "*") ? "*" : rule.source_address_prefixes[0]) : null


            # Defines the destination address prefix for the security rule:
            # - If destination_address_prefixes list has elements and contains letters/asterisk:
            # - Use "*" if present in the list
            # - Otherwise use the first element of the list
            # - If no elements or no letters/asterisks are found, set to null
            destination_address_prefixes = length(rule.destination_address_prefixes) == 0 ? data.azurerm_subnet.subnet["${rule.destination_subnet_name}-${rule.destination_subnet_vnet_name}"].address_prefixes : (alltrue([for p in rule.destination_address_prefixes : (regex("[A-Za-z\\*]", p) == null)]) ? rule.destination_address_prefixes : null)
            destination_address_prefix   = length(rule.destination_address_prefixes) > 0 && (anytrue([for p in rule.destination_address_prefixes : (length(regexall("[A-Za-z\\*]", p)) > 0)])) ? (contains(rule.destination_address_prefixes, "*") ? "*" : rule.destination_address_prefixes[0]) : null

            nsg_name  = key
            direction = "Outbound"
          }
          ] : [
          for i, ts_definition in local.target_services[rule.target_service] : {
            name                    = "${rule.name}-${i}"
            priority                = rule.priority + i
            access                  = rule.access
            protocol                = rule.target_service != null ? title(ts_definition.protocol) : rule.protocol
            source_port_ranges      = contains(rule.source_port_ranges, "*") ? null : rule.source_port_ranges
            source_port_range       = contains(rule.source_port_ranges, "*") ? "*" : null
            destination_port_ranges = rule.target_service != null ? ts_definition.port_ranges : (contains(rule.destination_port_ranges, "*") ? null : rule.destination_port_ranges)
            destination_port_range  = rule.target_service != null ? null : (contains(rule.destination_port_ranges, "*") ? "*" : null)


            # Defines the source address prefixes for outbound security rule:
            # - If source_address_prefixes list is empty:
            #   - Use subnet's address prefixes from target subnet
            # - If source_address_prefixes contains elements:
            #   - If all prefixes are numeric (no letters), use them as is
            #     - If any prefix contains letters/asterisk:
            #       - Use "*" if present in the list
            #     - Otherwise use the first prefix
            source_address_prefixes = length(rule.source_address_prefixes) == 0 ? (nsg.target_subnet_id != null ? [nsg.target_subnet_cidr] : data.azurerm_subnet.subnet["${nsg.target_subnet_name}-${nsg.target_subnet_vnet_name}"].address_prefixes) : (alltrue([for p in rule.destination_address_prefixes : (length(regexall("[A-Za-z]", p)) == 0)]) ? rule.destination_address_prefixes : null)
            source_address_prefix   = length(rule.source_address_prefixes) > 0 && (anytrue([for p in rule.source_address_prefixes : (length(regexall("[A-Za-z\\*]", p)) > 0)])) ? (contains(rule.source_address_prefixes, "*") ? "*" : rule.source_address_prefixes[0]) : null


            # Defines the destination address prefix for the security rule:
            # - If destination_address_prefixes list has elements and contains letters/asterisk:
            # - Use "*" if present in the list
            # - Otherwise use the first element of the list
            # - If no elements or no letters/asterisks are found, set to null
            destination_address_prefixes = length(rule.destination_address_prefixes) == 0 ? data.azurerm_subnet.subnet["${rule.destination_subnet_name}-${rule.destination_subnet_vnet_name}"].address_prefixes : (alltrue([for p in rule.destination_address_prefixes : (regex("[A-Za-z\\*]", p) == null)]) ? rule.destination_address_prefixes : null)
            destination_address_prefix   = length(rule.destination_address_prefixes) > 0 && (anytrue([for p in rule.destination_address_prefixes : (length(regexall("[A-Za-z\\*]", p)) > 0)])) ? (contains(rule.destination_address_prefixes, "*") ? "*" : rule.destination_address_prefixes[0]) : null

            nsg_name  = key
            direction = "Outbound"
          }
        ])

      ])
    ]
    )
  )
}
