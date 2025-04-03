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

variable "subnet_a" {
  type        = string
  description = "CIDR range of subnet a"
  default     = "10.0.1.0/24"
  validation {
    condition     = provider::assert::cidrv4(var.subnet_a)
    error_message = "Subnet a doesn't have a valid CIDR range"
  }
}

variable "subnet_b" {
  type        = string
  description = "CIDR range of subnet b"
  default     = "10.1.1.0/24"
  validation {
    condition     = provider::assert::cidrv4(var.subnet_b)
    error_message = "Subnet b doesn't have a valid CIDR range"
  }
}

variable "subnet_c" {
  type        = string
  description = "CIDR range of subnet c"
  default     = "10.2.1.0/24"
  validation {
    condition     = provider::assert::cidrv4(var.subnet_c)
    error_message = "Subnet c doesn't have a valid CIDR range"
  }
}
