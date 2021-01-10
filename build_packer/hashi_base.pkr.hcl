
variable "hashi_lxd_repo_directory" {}

variable "hashi_common_repo_directory" {}

locals {
  services_path = "/home/ubuntu/packer/services"
  scripts_path = "/home/ubuntu/packer/scripts"
}

source "lxd" "base-image" {
  image = "ubuntu-daily:focal"
  profile = "default"
  output_image = "lxd-hashi-base"
  # name
  # launch_config = {
  # }
}

/*
build {
  sources = ["source.lxd.base-image"]

  provisioner "file" {
    source = "${var.hashi_common_repo_directory}/build/vm_image/installation_scripts/"
    destination = "/home/vagrant/scripts"
  }
  provisioner "shell" {
    inline = [
      "cp -r /home/vagrant/scripts/installation_scripts/* /home/vagrant/scripts/"
    ]
  }
}
*/

build {
  sources = ["source.lxd.base-image"]

  # "sudo apt-get --yes --force-yes -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade"

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [

      "sudo apt-get update -y",
      #"sudo apt-get upgrade -y",

      "sudo apt install -y apt-transport-https ca-certificates",
      "sudo apt install -y gnupg-agent curl vim software-properties-common net-tools",
      "sudo apt install -y zip unzip npm nodejs jq python3-pip python3-testresources sshpass",

      "sudo apt autoremove -y",
      "sudo apt-get update -y"
    ]
  }

  provisioner "shell" {
    inline = [
      #"sudo mkdir -p /home/ubuntu",
      #"sudo useradd --system --home /home/ubuntu --shell /bin/false vagrant",
      #"sudo useradd --system --home /home/ubuntu --shell /bin/false ubuntu",

      "sudo mkdir -p ${local.scripts_path}",
      "sudo mkdir -p ${local.services_path}",
      "sudo chown ubuntu:ubuntu ${local.scripts_path}",
      "sudo chown ubuntu:ubuntu ${local.services_path}",

      "sudo mkdir -p /home/ubuntu/.docker/"  # should this be copied to /home/root/.docker?
    ]
  }

  provisioner "file" {
    source = "${var.hashi_common_repo_directory}/build/vm_image/installation_scripts/" # trailing slash is important (https://www.packer.io/docs/provisioners/file.html#directory-uploads)
    destination = "${local.scripts_path}"
  }

  provisioner "file" {
    source = "${var.hashi_common_repo_directory}/services/"
    destination = "${local.services_path}"
  }

  provisioner "shell" {
    # file provisioner seems to have a bug with LXD where the paths aren't right (compared to behaviour with vagrant), so we'll fix this here
    inline = [
      "mv ${local.scripts_path}/installation_scripts/* ${local.scripts_path}",
      "rm -rf ${local.scripts_path}/installation_scripts/",
      "mv ${local.services_path}/services/* ${local.services_path}",
      "rm -rf ${local.services_path}/services/"
    ]
  }

  provisioner "shell" {
    inline = [

      "sudo chmod +x -R ${local.scripts_path}/",

      "sudo cp ${local.scripts_path}/hashicorp-sudoers /etc/sudoers.d/hashicorp-sudoers",
      "sudo -H pip3 install -r ${local.scripts_path}/python-requirements.txt",

      "sudo ${local.scripts_path}/install-docker.sh",

      "sudo ${local.scripts_path}/install-ansible__vagrant.sh",

      "sudo ${local.scripts_path}/install-consul.sh",
      "sudo ${local.scripts_path}/install-consul-template.sh",
      "sudo ${local.scripts_path}/install-go-discover.sh",
      "sudo ${local.scripts_path}/install-nomad.sh",
      "sudo ${local.scripts_path}/install-vault.sh",
      # removed for vagrant: stackdriver, fluentd, ntp
      "sudo rm -rf /home/ubuntu/packer"
    ]
  }
}
