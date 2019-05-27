
module "two_subnets" {
  source = "../"

  base_cidr_block = "10.64.0.0/12"
  max_regions     = 8
  regions = [
    {
      name      = "uswest"
      max_zones = 8
      zones = [
        { name = "a" },
        { name = "b" },
        { name = "d" },
      ]
    },
    {
      name      = "useast"
      max_zones = 4
      zones = [
        { name = "a" },
        { name = "c" },
      ]
    },
    {
      name      = "euwest"
      max_zones = 8
      zones = [
        { name = "b" },
        { name = "c" },
      ]
    },
  ]
  max_subnets_per_zone = 2
  zone_subnets = [
    { name = "public" },
    { name = "private" },
  ]
}

data "testing_assertions" "two_subnets" {
  subject = "Network plan with two subnets per zone"

  equal "region_count" {
    statement = "has three regions"

    got  = length(module.two_subnets.regions)
    want = 3
  }

  equal "region_uswest" {
    statement = "has expected settings for uswest region"

    got = module.two_subnets.regions.uswest
    want = {
      name       = "uswest"
      cidr_block = "10.64.0.0/15"
      subnets = tomap({
        uswest-a-private = {
          name        = "uswest-a-private"
          region_name = "uswest"
          zone_name   = "a"
          subnet_name = "private"
          cidr_block  = "10.64.32.0/19"
        }
        uswest-a-public = {
          name        = "uswest-a-public"
          region_name = "uswest"
          zone_name   = "a"
          subnet_name = "public"
          cidr_block  = "10.64.0.0/19"
        }
        uswest-b-private = {
          name        = "uswest-b-private"
          region_name = "uswest"
          zone_name   = "b"
          subnet_name = "private"
          cidr_block  = "10.64.96.0/19"
        }
        uswest-b-public = {
          name        = "uswest-b-public"
          region_name = "uswest"
          zone_name   = "b"
          subnet_name = "public"
          cidr_block  = "10.64.64.0/19"
        }
        uswest-d-private = {
          name        = "uswest-d-private"
          region_name = "uswest"
          zone_name   = "d"
          subnet_name = "private"
          cidr_block  = "10.64.160.0/19"
        }
        uswest-d-public = {
          name        = "uswest-d-public"
          region_name = "uswest"
          zone_name   = "d"
          subnet_name = "public"
          cidr_block  = "10.64.128.0/19"
        }
      })
    }
  }
}

