base_cidr_block = "10.0.0.0/10"

max_regions = 8
regions = [
  {
    name      = "uswest"
    max_zones = 4
    zones = [
      { name = "a" },
      { name = "c" },
      # Two other zone addresses still available to be allocated.
    ]
  },
  {
    name      = "euwest"
    max_zones = 4
    zones = [
      { name = "a" },
      { name = "b" },
      { name = "d" },
      { name = "e" },
      # All zone addresses used, so no more can be added here.
    ]
  },
]

max_subnets_per_zone = 2
zone_subnets = [
  { name = "private" },
  { name = "public" },
]
