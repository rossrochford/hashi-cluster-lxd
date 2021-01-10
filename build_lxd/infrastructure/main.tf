# or alternatively: https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/resources/lxc.md  https://andrewbeaton.net/2019/10/20/using-terraform-to-create-a-linux-container-in-proxmox/
# for KVM, this is what apollo13 on gitter uses (says he's not 100% happy with it, but it's probably fine?) : https://github.com/dmacvicar/terraform-provider-libvirt

terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
      version = "1.5.0"
    }
  }
}

provider "lxd" {
  generate_client_certificates = true
  accept_remote_certificate    = true
  config_dir = "/var/snap/lxd/common/config"
  # also see lxd_remote () block (https://github.com/terraform-lxd/terraform-provider-lxd/blob/master/docs/index.md)
}

variable "hashi_lxd_repo_directory" {
  default = "/home/ross/code/hashi-cluster/hashi-cluster-lxd"
}

variable "hashi_common_repo_directory" {
  default = "/home/ross/code/hashi-cluster/hashi-cluster-common"
}


locals {
  instance_configs = jsondecode(file(
    "${var.hashi_lxd_repo_directory}/build_lxd/conf/lxd-instances.json"
  ))
}


module "cluster_instances" {
  source = "./modules/lxd_container_instance"

  for_each = { for instance_dict in local.instance_configs : instance_dict.name => instance_dict }

  container_instance_name = each.key
  image = "lxd-hashi-base"
  node_type = each.value.node_type
  network_name = lxd_network.hashi_network1.name
  startup_script_filepath = "./init_scripts/initialize_instance.sh"
  storage_pool_name = lxd_storage_pool.hashi_storage_pool1.name
  ipv4_address = each.value.ip
  public_key_filepath = "/home/ross/.ssh/id_ed25519_lxd.pub"
  private_key_filepath = "/home/ross/.ssh/id_ed25519_lxd"
  environment_variables = {
    "environment.NODE_NAME" = each.value.name
    "environment.NODE_TYPE" = each.value.node_type
    "environment.NODE_IP" = each.value.ip
  }
  files_to_transfer = [
    ["/home/ross/.ssh/id_ed25519_lxd.pub", "/root/.ssh/id_ed25519_lxd.pub"],
    ["/home/ross/.ssh/id_ed25519_lxd", "/root/.ssh/id_ed25519_lxd"],
    ["/home/ross/.ssh/id_ed25519_lxd.pub", "/home/ubuntu/.ssh/id_ed25519_lxd.pub"],
    ["/home/ross/.ssh/id_ed25519_lxd", "/home/ubuntu/.ssh/id_ed25519_lxd"],
    ["/tmp/hashi_common.zip", "/home/ubuntu/hashi_common.zip"],
    ["/tmp/hashi_lxd.zip", "/home/ubuntu/hashi_lxd.zip"],
    ["/tmp/ansible-data/vault-tls-certs.zip", "/home/ubuntu/vault-tls-certs.zip"]  # note: transferring to /tmp doesn't work (presumably /tmp is deleted after init script) so we move this later
  ]
  shared_directories = [
    ["vagrant-shared", "/home/ross/code/hashi-cluster/vagrant_shared", "/vagrant_shared"]
  ]
}


# todo:
# test ansible, adjust config
# verify env variables are getting passed
# add remaining machine groups (clients, vault, traefik)
# create master init script (runs terraform, creates vault certs, launches ansible)
# forward port from localhost:8085 to traefik instance


/*
remote-exec isn't implemented, here is a workaround:

provisioner "local-exec" {
  command = <<EXEC
lxc exec ${var.instance_name} -- bash -xe -c '
echo "this runs inside the container!"
'
EXEC
}
*/

/*
      config.vm.provision "file", source: REPO_COMMON + "/build", destination: "/tmp/scripts/build"
      config.vm.provision "file", source: REPO_VAGRANT + "/build_vagrant", destination: "/tmp/scripts/build_vagrant"
      config.vm.provision "file", source: REPO_COMMON +  "/services", destination: "/tmp/scripts/services"
      config.vm.provision "file", source: REPO_COMMON + "/utilities", destination: "/tmp/scripts/utilities"

      if server_data["node_type"] == "hashi_client"
        tarballs_path = REPO_VAGRANT + "/operations/docker_tarballs"
        srv.vm.synced_folder tarballs_path, "/docker_tarballs"
        if NOMAD_SHARED_PATH != nil
          srv.vm.synced_folder VAGRANT_SHARED_PATH, "/vagrant_shared"
        else
          puts "warning: missing VAGRANT_SHARED_PATH"
        end
      end

      if File.exist?("/tmp/ansible-data/vault-tls-certs.zip")
        config.vm.provision "file", source: "/tmp/ansible-data/vault-tls-certs.zip", destination: "/tmp/ansible-data/vault-tls-certs.zip"
      end
*/
