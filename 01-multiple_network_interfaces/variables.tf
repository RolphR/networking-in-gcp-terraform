/*
 * Generic variables
 */

variable "project_id" {
  type        = string
  description = "Project ID in which this example is deployed"
}

variable "region" {
  type        = string
  description = "Default region in which regional resources are deployed"
}

variable "zone" {
  type        = string
  description = "Default zone in which zonal resources are deployed"
}

/*
 * Example specific variables
 */

variable "subnets" {
  type        = map(map(string))
  description = "Map of subnet CIDR ranges"
  default = {
    internet = {
      appliance = "10.0.0.0/24"
    }
    web = {
      appliance = "10.1.0.0/24"
      main      = "10.1.1.0/24"
    }
    backend = {
      appliance = "10.2.0.0/24"
      main      = "10.2.1.0/24"
    }
    onprem = {
      appliance = "10.3.0.0/24"
      main      = "10.3.1.0/24"
    }
  }
  validation {
    condition = alltrue([
      for network, subnets in var.subnets :
      alltrue([
        for name, cidr in subnets :
        provider::assert::cidrv4(cidr)
      ])
    ])
    error_message = "All subnets must have a valid CIDR range"
  }
}

variable "networks" {
  type        = map(string)
  description = "Map of network CIDR ranges, used by the appliance to route traffic"
  default = {
    internet = "10.0.0.0/16"
    web      = "10.1.0.0/16"
    backend  = "10.2.0.0/16"
    onprem   = "10.0.0.0/8"
  }
  validation {
    condition = alltrue([
      for name, cidr in var.networks :
      provider::assert::cidrv4(cidr)
    ])
    error_message = "All networks must have a valid CIDR range"
  }
}
