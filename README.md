# Terraform Network Address Planning Module

This module is a local-only module that can construct IP address plans based
on a higher-level specification of the needed network objects.

It produces plans based on the following concepts:

- Region: a set of resources in a similar geographical location that have
  open communication within them.

- Zone: a sub-portion of a region that shares some common requirement, like
  a power supply, or a single building, etc.

- Subnet: a sub-portion of a zone that is separated only so that it can have
  a different configuration, such as a more or less restrictive set of
  access controls.

Each level in this hierarchy is allocated a certain number of prefix bits in
generated subnet addresses. The result is a CIDR prefix per region and a
CIDR prefix per subnet in each region. Zones also have an associated address
prefix, but it is not exposed directly and is rather just used as part of
the addresses of the subnets in it.

The result, then, is a slightly flatter heirarchy with only two levels, each
having its own prefix length and network addresses:

- Region: as above

- Subnets per zone: the zone and subnet levels are combined together to
  produce a flat set of subnets per region.

## Networking Address Planning Model

When designing an address plan, we need to first decide what will be its
capacity for regions. That is, the maximum number of regions it can support
without renumbering. Because a region is identified by a fixed number of bits
in the address, the maximum number of regions is always a power of two and
is always at least one.

For the purposes of this module, we also decide on a fixed maximum number of
subnets per zone. In many cases, this can be just one. If you follow the model
of having separate public/private subnets then this might be two. This module
assumes that the subnet assignments are consistent across all zones in all
regions.

The `max_regions` and `max_subnets_per_zone` input variables contain these
two values, and decide how many bits of the IP address prefix will be allocated
to each concetp. `max_regions` is required, while `max_subnets_per_zone`
defaults to one. If either is set to one then no bits at all are assigned.

```hcl
  max_regions          = 8
  max_subnets_per_zone = 2
```

With those upper limits decided, we can then proceed to define individual
regions and subnets. We don't need to allocate all of the available addresses
immediately, but we must not have more objects defined than there are addresses
available for them.

### Defining Individual Subnet Types

The optional `zone_subnets` variable defines specific subnet types which should
be allocated for each zone for each region:

```hcl
  zone_subnets = [
    { name = "private" },
    { name = "public" },
  ]
```

When multiple subnet types are defined, each one must be assigned a unique name
so that they can be distinguished, e.g. to apply different settings to the
private ones vs. the public ones. At most one subnet may have a name of `null`,
in which case its name will not include a subnet qualifier at all. That rule is
most useful when there is only one subnet per region-zone, and that's the
default if `zone_subnets` isn't set at all.

The subnet types are assigned network numbers based on their indices in the
list, so in the above example the "private" subnets have network number zero
and the "public" subnets have network number one.

### Base CIDR Block

The network addresses produced by address planning are all placed under the
base CIDR given in `base_cidr_block`.

```hcl
  base_cidr_block = "10.0.0.0/10"
```

When choosing a base CIDR block, be mindful of the fact that you need to leave
room for this prefix to grow to include the bits to identify the regions, the
zones within each region, and the subnets within each zone, and still leave
enough bits left over for a suitable number of hosts in each subnet.

The above example uses an IPv4 prefix, but IPv6 prefixes are also supported.
If the base CIDR block is an IPv6 prefix then all generated network prefixes
will also have IPv6 addresses.

### Defining Individual Regions

The `regions` variable defines specific regions which should be allocated.
Each one is represented by an object with the following attributes:

- `name` - a string giving a unique name that will be used to identify the
  region.
- `max_zones` - number giving the maximum capacity for zones in this region.
  This decides how many address bits are allocated to identify zones in this
  region, and should therefore be a power of two greater than or equal to 1.
- `zones` - list of objects that each defines an individual zone in this
  region. Each object has a single attribute, `name`, which is a unique string
  used to distinguish each zone from the others in the same region.

```hcl
  regions = [
    {
      name      = "uswest"
      max_zones = 4
      zones     = [
        { name = "a" },
        { name = "c" },
        # Two other zone addresses still available to be allocated.
      ]
    },
    {
      name      = "euwest"
      max_zones = 4
      zones     = [
        { name = "a" },
        { name = "b" },
        { name = "d" },
        { name = "e" },
        # All zone addresses used, so no more can be added here.
      ]
    },
  ]
```

The regions and the zones within each region are assigned network numbers
based on their indices in the respective lists. In the above example, the
region "uswest" is assigned the network number zero. Its zone named "c" is
assigned a zone network number of one.

## Outputs

The main output of this module is called `regions`, and it consists of
a two-level heirarchical data structure describing first the address
assigned to each region and then the addresses assigned to each subnet
in each region, where the total number of subnets is the number of defined
zones multipled by the number of defined subnet types.

With the example values shown above, the module produces the following
network address plan:

```
regions = {
  "euwest" = {
    "cidr_block" = "10.8.0.0/13"
    "name" = "euwest"
    "subnets" = {
      "euwest-a-private" = {
        "cidr_block" = "10.8.0.0/16"
        "name" = "euwest-a-private"
        "region_name" = "euwest"
        "subnet_name" = "private"
        "zone_name" = "a"
      }
      "euwest-a-public" = {
        "cidr_block" = "10.9.0.0/16"
        "name" = "euwest-a-public"
        "region_name" = "euwest"
        "subnet_name" = "public"
        "zone_name" = "a"
      }
      "euwest-b-private" = {
        "cidr_block" = "10.10.0.0/16"
        "name" = "euwest-b-private"
        "region_name" = "euwest"
        "subnet_name" = "private"
        "zone_name" = "b"
      }
      "euwest-b-public" = {
        "cidr_block" = "10.11.0.0/16"
        "name" = "euwest-b-public"
        "region_name" = "euwest"
        "subnet_name" = "public"
        "zone_name" = "b"
      }
      "euwest-d-private" = {
        "cidr_block" = "10.12.0.0/16"
        "name" = "euwest-d-private"
        "region_name" = "euwest"
        "subnet_name" = "private"
        "zone_name" = "d"
      }
      "euwest-d-public" = {
        "cidr_block" = "10.13.0.0/16"
        "name" = "euwest-d-public"
        "region_name" = "euwest"
        "subnet_name" = "public"
        "zone_name" = "d"
      }
      "euwest-e-private" = {
        "cidr_block" = "10.14.0.0/16"
        "name" = "euwest-e-private"
        "region_name" = "euwest"
        "subnet_name" = "private"
        "zone_name" = "e"
      }
      "euwest-e-public" = {
        "cidr_block" = "10.15.0.0/16"
        "name" = "euwest-e-public"
        "region_name" = "euwest"
        "subnet_name" = "public"
        "zone_name" = "e"
      }
    }
  }
  "uswest" = {
    "cidr_block" = "10.0.0.0/13"
    "name" = "uswest"
    "subnets" = {
      "uswest-a-private" = {
        "cidr_block" = "10.0.0.0/16"
        "name" = "uswest-a-private"
        "region_name" = "uswest"
        "subnet_name" = "private"
        "zone_name" = "a"
      }
      "uswest-a-public" = {
        "cidr_block" = "10.1.0.0/16"
        "name" = "uswest-a-public"
        "region_name" = "uswest"
        "subnet_name" = "public"
        "zone_name" = "a"
      }
      "uswest-c-private" = {
        "cidr_block" = "10.2.0.0/16"
        "name" = "uswest-c-private"
        "region_name" = "uswest"
        "subnet_name" = "private"
        "zone_name" = "c"
      }
      "uswest-c-public" = {
        "cidr_block" = "10.3.0.0/16"
        "name" = "uswest-c-public"
        "region_name" = "uswest"
        "subnet_name" = "public"
        "zone_name" = "c"
      }
    }
  }
}
```

Some virtual network implementations allow creating subnets across multiple
regions with the same Terraform provider configuration, varying the region
on a per-resource basis rather than a per-provider basis. For such providers,
the `subnets` output duplicates the subnet information from the `regions`
output into a single flat map, allowing all of the subnets to potentially
be created by a single resource block, or to use one resource block per
distinct subnet type.

Finally, the `region_peers` output is a set of sets where each inner set is
a pair of regions and the overall set contains every combination of two
distinct regions. For situations where it is desired to create a full mesh of
peering connections between regions, the `region_peers` set describes all of
the peering connections that must be created.
