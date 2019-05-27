variable "base_cidr_block" {
  type        = string
  description = "The CIDR prefix that will contain all of the assigned networks."
}

variable "max_regions" {
  type        = number
  description = "The maximum number of regions to be supported by this address plan. Set this higher than the length of 'regions' to allow for future expansion without renumbering. This number will be rounded up to the next highest power of two."
}

variable "regions" {
  type = list(object({
    name      = string
    max_zones = number
    zones = list(object({
      name = string
    }))
  }))
  description = "List of region descriptions to create regional networks for. This must be no longer than max_regions elements, and future updates should only append to this list in order to avoid renumbering existing networks."
}

variable "max_subnets_per_zone" {
  type        = number
  description = "The maximum number of subnets per zone to be suported by this address plan. Set this higher than the length of 'zone_subnets' to allow for future expansion without renumbering. This number will be rounded up to the next highest power of two."
  default     = 1
}

variable "zone_subnets" {
  type = list(object({
    name = string
  }))
  description = "List of subnets to create for each zone in each region. This must be no longer than max_subnets_per_zone elements, and future updates should only append to this list in order to avoid renumbering existing networks."
  default = [
    {
      name = null # Null means to create no extra suffix for this one
    },
  ]
}

variable "tier_separator" {
  type        = string
  description = "String to join together the names of different tiers to produce fully-qualified names."
  default     = "-"
}
