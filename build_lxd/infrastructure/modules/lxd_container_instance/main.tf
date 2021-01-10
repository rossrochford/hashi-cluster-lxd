terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
      version = "1.5.0"
    }
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user_data.tmpl")
  /*vars = {
    public_key_string = file(var.public_key_filepath)
  }*/
}


locals {
  empty_script = <<EOF
#!/bin/bash
# empty init script
EOF

  container_config_map = {
    "boot.autostart" = false  # don't boot container when LXD starts
    "user.user-data" = data.template_file.user_data.rendered
    "user.access_interface" = "eth0"  # or set on profile
    "security.privileged" = true
    "security.nesting" = true
    #"lxc.apparmor.allow_nesting" = "1"  # is this redundant?
  }
  server_cpu_limits_config = {
    # pin server containers to a single cpu core at 50% capacity (based on: https://discuss.linuxcontainers.org/t/cpu-limits-confusion/1837/2)
    "limits.cpu" = "1"
    "limits.cpu.allowance" = var.server_cpu_limit
  }

  server_node_types = ["hashi_server", "vault", "traefik"]
}

/*resource "lxd_volume" "container-volume" {
  name = "${var.container_instance_name}-volume"
  pool = var.storage_pool_name

  #depends_on = [lxd_container.container-instance]
}*/


resource "lxd_container" "container-instance" {
  name      = var.container_instance_name
  image     = var.image
  ephemeral = false  # don't destroy container upon termination (true causes terraform to crash on destroy)

  # merge container_config_map with environment_variables, add cpu limits if this is a server node
  config = contains(local.server_node_types, var.node_type) ? merge(local.container_config_map, local.server_cpu_limits_config, var.environment_variables) : merge(local.container_config_map, var.environment_variables)

  /*config = {
    "environment.NODE_NAME" = "test-name"
    "environment.NODE_TYPE" = "hashi_server"
    "boot.autostart" = false  # don't boot container when LXD starts
    "user.user-data" = data.template_file.user_data.rendered
    "user.access_interface" = "eth0"  # or set on profile
  }*/

  /*device {
    name = "${var.container_instance_name}-volume-device"
    type = "disk"
    properties = {
      path = "/vagrant_shared"
      source = lxd_volume.container-volume.name
      pool = var.storage_pool_name
    }
  }*/

  device {
    name = "eth0"
    type = "nic"

    properties = {
      "nictype" = "bridged"
      "parent"  = var.network_name
      "host_name" = var.container_instance_name
      "ipv4.address" = var.ipv4_address
    }
  }

  device {
    type = "disk"
    name = "root"

    properties = {
      pool = "default"
      path = "/"
    }
  }

  file {
    content = var.startup_script_filepath == null ? local.empty_script : file(var.startup_script_filepath)
    target_file = "/home/ubuntu/initialize_instance.sh"
    create_directories = true
    mode = 0755
  }

  dynamic "file" {
    for_each = var.files_to_transfer
    content {
      source = file.value[0]
      target_file = file.value[1]
      create_directories = true
    }
  }

  dynamic "device" {
    for_each = var.shared_directories
    content {
      name = device.value[0]
      type = "disk"
      properties = {
        source = device.value[1]
        path = device.value[2]
      }
    }
  }

  provisioner "local-exec" {
    command = <<EXEC
lxc exec ${var.container_instance_name} -- bash -xe -c '
/home/ubuntu/initialize_instance.sh
'
EXEC
  }
  /*
  # lxc config device add {container-name} {name} disk source={/path/to/source/dir/} path={/path/to/dest
  # lxc config device add mycontainer sharedtmp disk path=/tmp/share_on_guest source=/tmp/share_on_host
  */

  /*depends_on = [
    lxd_volume.container-volume
    lxd_storage_pool.default,
    lxd_network.default_network,
    lxd_profile.hashi_profile1
  ]*/
}


/*

  dynamic "setting" {
    for_each = var.settings
    content {
      namespace = setting.value["namespace"]
      name = setting.value["name"]
      value = setting.value["value"]
    }
  }


*/


/*
lxc network attach lxdbr0 c1 eth0 eth0
lxc config device set c1 eth0 ipv4.address 10.99.10.42
*/

