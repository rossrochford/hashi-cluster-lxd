
# There seem to be issues creating pools using lxd_storage_pool, instead
# create pool in lxc and import it into terraform
#   $ lxc storage create hashi_storage_pool1 dir; lxc storage list
#   $ terraform import lxd_storage_pool.hashi_storage_pool1 hashi_storage_pool1


resource "lxd_storage_pool" "hashi_storage_pool1" {
  name = var.storage_pool_name
  driver = "dir"
  config = {
    source = "/var/snap/lxd/common/lxd/storage-pools/${var.storage_pool_name}"
  }
}
