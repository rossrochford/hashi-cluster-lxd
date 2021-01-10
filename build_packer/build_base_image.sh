#!/bin/bash


#UBUNTU_IMAGE_FILEPATH="$HASHI_VAGRANT_REPO_DIRECTORY/build_packer/ubuntu2004.box"  # todo: move file
UBUNTU_IMAGE_FILEPATH="/home/ross/code/hashi-cluster/hashi-cluster-vagrant/build_packer/ubuntu2004.box"
PACKER_DIR="$HASHI_VAGRANT_REPO_DIRECTORY/build_lxd_packer"

cd $PACKER_DIR || exit


#if [ ! -f "$UBUNTU_IMAGE_FILEPATH" ]; then
#  wget https://app.vagrantup.com/generic/boxes/ubuntu2004/versions/3.1.12/providers/virtualbox.box -o "$UBUNTU_IMAGE_FILEPATH"
#fi


rm -rf "$PACKER_DIR/base_image"
rm -rf "$PACKER_DIR/packer_cache"

packer build -force \
   -var="hashi_lxd_repo_directory=$HASHI_LXD_REPO_DIRECTORY" \
   -var="hashi_common_repo_directory=$HASHI_COMMON_REPO_DIRECTORY" \
   "$PACKER_DIR/hashi_base.pkr.hcl"
