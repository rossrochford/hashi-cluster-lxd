variable "image" {
  # "/home/ross/code/hashi-cluster/hashi-cluster-vagrant/build_packer/base_image/package.box"
  default = "ubuntu:20.04"
}

variable "container_instance_name" {}

variable "node_type" {}
#variable "profile_name" {
  // lxd_profile.hashi_profile1.name
#}

variable "storage_pool_name" {
  // lxd_storage_pool.default.name
}

variable "startup_script_filepath" {
  default = null
}

variable "network_name" {}

variable "ipv4_address" {}

variable "private_key_filepath" {}

variable "public_key_filepath" {}

variable "files_to_transfer" {
  type = list
}

variable "shared_directories" {
  type = list
}

variable "server_cpu_limit" {
  default = "50%"  # percentage expected
  type = string
}

variable "environment_variables" {
  type = map
}