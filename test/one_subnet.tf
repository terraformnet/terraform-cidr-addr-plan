
module "one_subnet" {
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
}

data "testing_assertions" "one_subnet" {
  subject = "Network plan with one subnet per zone"

  equal "region_count" {
    statement = "has three regions"

    got  = length(module.one_subnet.regions)
    want = 3
  }

  equal "region_uswest" {
    statement = "has expected settings for uswest region"

    got = module.one_subnet.regions.uswest
    want = {
      name       = "uswest"
      cidr_block = "10.64.0.0/15"
      subnets = tomap({
        uswest-a = {
          name        = "uswest-a"
          region_name = "uswest"
          zone_name   = "a"
          subnet_name = ""
          cidr_block  = "10.64.0.0/18"
        }
        uswest-b = {
          name        = "uswest-b"
          region_name = "uswest"
          zone_name   = "b"
          subnet_name = ""
          cidr_block  = "10.64.64.0/18"
        }
        uswest-d = {
          name        = "uswest-d"
          region_name = "uswest"
          zone_name   = "d"
          subnet_name = ""
          cidr_block  = "10.64.128.0/18"
        }
      })
    }
  }

  equal "region_useast" {
    statement = "has expected settings for useast region"

    got = module.one_subnet.regions.useast
    want = {
      name       = "useast"
      cidr_block = "10.66.0.0/15"
      subnets = tomap({
        useast-a = {
          name        = "useast-a"
          region_name = "useast"
          zone_name   = "a"
          subnet_name = ""
          cidr_block  = "10.66.0.0/17"
        }
        useast-c = {
          name        = "useast-c"
          region_name = "useast"
          zone_name   = "c"
          subnet_name = ""
          cidr_block  = "10.66.128.0/17"
        }
      })
    }
  }
}

