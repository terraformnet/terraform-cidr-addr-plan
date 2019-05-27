base_cidr_block = "10.0.0.0/10"

max_regions = 8
regions = [
  {
    name      = "us-west"
    max_zones = 4
    zones = [
      { name = "a" },
      { name = "b" },
    ]
  },
  {
    name      = "us-east"
    max_zones = 4
    zones = [
      { name = "a" },
      { name = "b" },
    ]
  },
  {
    name      = "eu-west"
    max_zones = 4
    zones = [
      { name = "a" },
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
