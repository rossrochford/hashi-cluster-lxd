# https://github.com/terraform-lxd/terraform-provider-lxd/blob/master/docs/resources/network.md

resource "lxd_network" "hashi_network1" {
  name = "hashi_network1"
  type = "bridge"
  config = {
    "ipv4.address" = "10.150.19.1/24"
    "ipv4.nat"     = "true"  # this is required for internet connectivity, I think
    "ipv4.firewall" = "true"
    "ipv6.address" = "auto"
    "ipv6.nat"     = "true"
    "ipv6.firewall" = "true"
    # some additional security configs: https://lxd.readthedocs.io/en/latest/security/#bridged-nic-security but the docs suggest that enabling them may affect Nomad containers from using the parent network.
  }
}

resource "lxd_profile" "hashi_profile1" {
  name = "hashi_profile1"

  /*
  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype = "bridged"
      parent  = lxd_network.hashi_network1.name
    }
  }*/

  device {
    type = "disk"
    name = "root"

    properties = {
      pool = "default"
      path = "/"
    }
  }
}

# todo: read about firewalls: https://lxd.readthedocs.io/en/latest/networks/

# networking docs https://lxd.readthedocs.io/en/latest/networks/#network-bridge


# lxc config device add hip-aardvark eth0 nic nictype=bridged parent=br0 name=eth0


# might be useful for traefik? https://lxd.readthedocs.io/en/latest/dev-lxd/