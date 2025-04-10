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
variable "consumer_subnets" {
  type        = map(string)
  description = "Regional consumer subnets"
  default = {
    "europe-west4" = "10.0.0.0/16"
    "us-central1"  = "10.1.0.0/16"
  }
  validation {
    condition = alltrue([
      for region, cidr in var.consumer_subnets :
      provider::assert::cidrv4(cidr)
    ])
    error_message = "All subnets must have a valid CIDR range"
  }
}

variable "producer_subnets" {
  type        = map(string)
  description = "Regional producer subnets"
  default = {
    "europe-west4" = "10.0.0.0/16"
    "us-central1"  = "10.1.0.0/16"
  }
  validation {
    condition = alltrue([
      for region, cidr in var.producer_subnets :
      provider::assert::cidrv4(cidr)
    ])
    error_message = "All subnets must have a valid CIDR range"
  }
}

variable "psc_subnets" {
  type        = map(string)
  description = "Regional PSC subnets"
  default = {
    "europe-west4" = "10.255.0.0/24"
    "us-central1"  = "10.255.1.0/24"
  }
  validation {
    condition = alltrue([
      for region, cidr in var.psc_subnets :
      provider::assert::cidrv4(cidr)
    ])
    error_message = "All subnets must have a valid CIDR range"
  }
}

variable "proxy_subnets" {
  type        = map(string)
  description = "Regional proxy subnets"
  default = {
    "europe-west4" = "100.64.0.0/16"
    "us-central1"  = "100.65.0.0/16"
  }
  validation {
    condition = alltrue([
      for region, cidr in var.proxy_subnets :
      provider::assert::cidrv4(cidr)
    ])
    error_message = "All subnets must have a valid CIDR range"
  }
}

variable "producer_template_version" {
  type        = string
  description = "Instance template version string"
  default     = "0"
  validation {
    condition     = provider::assert::regex("^[a-z0-9-]*[a-z0-9]$", var.producer_template_version)
    error_message = "invalid producer template version"
  }
}
