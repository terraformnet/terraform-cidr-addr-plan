
locals {
  region_bits = ceil(log(var.max_regions, 2))
  subnet_bits = ceil(log(var.max_subnets_per_zone, 2))

  regions = [
    for i, r in var.regions : {
      name    = r.name
      netnum  = i
      newbits = local.region_bits
      zones = [
        for i, z in r.zones : {
          local_name     = z.name
          region_name    = r.name
          qualified_name = "${r.name}${var.tier_separator}${z.name}"
          netnum         = i
          newbits        = ceil(log(r.max_zones, 2))
        }
      ]
    }
  ]
  subnets = [
    for i, s in var.zone_subnets : {
      name        = s.name
      name_suffix = s.name != null ? "${var.tier_separator}${s.name}" : ""
      netnum      = i
      newbits     = local.subnet_bits
    }
  ]
  zones = flatten([
    for r in var.regions : r.zones
  ])

  region_zones = flatten(local.regions.*.zones)
  base_regions = [
    for r in local.regions : {
      local_name = r.name
      cidr_block = cidrsubnet(var.base_cidr_block, r.newbits, r.netnum)
    }
  ]
  base_region_zones = flatten([
    for br in local.base_regions : [
      for z in local.region_zones : {
        local_name     = z.local_name
        region_name    = z.region_name
        qualified_name = "${br.local_name}${var.tier_separator}${z.local_name}"
        cidr_block     = cidrsubnet(br.cidr_block, z.newbits, z.netnum)
      }
      if z.region_name == br.local_name
    ]
  ])
  base_region_zone_subnets = [
    for pr in setproduct(local.base_region_zones, local.subnets) : {
      local_name     = pr[1].name
      zone_name      = pr[0].local_name
      region_name    = pr[0].region_name
      qualified_name = "${pr[0].qualified_name}${pr[1].name_suffix}"
      cidr_block     = cidrsubnet(pr[0].cidr_block, pr[1].newbits, pr[1].netnum)
    }
  ]

  region_names = toset(local.base_region_zone_subnets.*.region_name)
  region_zone_names = {
    for rz in local.region_zones : rz.region_name => rz.local_name...
  }
  subnet_names = toset(local.base_region_zone_subnets.*.local_name)

  all_subnets = {
    for brzs in local.base_region_zone_subnets : brzs.qualified_name => {
      name        = brzs.qualified_name
      subnet_name = brzs.local_name != null ? brzs.local_name : ""
      zone_name   = brzs.zone_name
      region_name = brzs.region_name
      cidr_block  = brzs.cidr_block
    }
  }
}

output "regions" {
  value = tomap({
    for br in local.base_regions : br.local_name => {
      name       = br.local_name
      cidr_block = br.cidr_block
      subnets    = { for k, v in local.all_subnets : k => v if v.region_name == br.local_name }
    }
  })

  description = "A map from each region name to an object describing that region's own CIDR prefix and a flattened map of each of the subnets within that region."
}

output "subnets" {
  value = tomap(local.all_subnets)

  description = "All of the subnets across all regions flattened into a single map, for more convenient use with for_each on a provider's subnet resource type."
}

output "region_peers" {
  value = toset([for pair in setproduct(local.region_names, local.region_names) : toset(pair) if pair[0] != pair[1]])

  description = "A set of sets containing all of the distinct combinations of regions, for use when creating a fully-connected set of peering arrangements."
}
