#!/bin/bash

if [ -f ".env" ]; then
  source .env
fi


if [[ -z $HASHI_LXD_REPO_DIRECTORY ]]; then
  echo "error: HASHI_LXD_REPO_DIRECTORY env variable must be set"; exit 1
fi

if [[ -z $HASHI_COMMON_REPO_DIRECTORY ]]; then
  echo "error: HASHI_COMMON_REPO_DIRECTORY env variable must be set"; exit 1
fi

# ensure base image exists
lxc image info lxd-hashi-base > /dev/null 2>&1
if [[ $? != 0 ]]; then
  ./build_packer/build_base_image.sh
fi

INSTANCE_CONFIG_FP="$HASHI_LXD_REPO_DIRECTORY/build_lxd/conf/lxd-instances.json"


# delete existing LXD resources  (workaround for some terraform errors)
# ---------------------------------------
INSTANCE_NAMES=$(cat $INSTANCE_CONFIG_FP | jq -r '[.[].name]|join(" ")')

for NAME in $INSTANCE_NAMES
do
  lxc delete $NAME > /dev/null 2>&1
done

#lxc storage delete hashi_storage_pool1 > /dev/null 2>&1
#lxc profile delete hashi_profile1 > /dev/null 2>&1
#lxc network delete hashi_network1 > /dev/null 2>&1
# -----------------------------------------


# for vagrant, assuming only 1 vault server at 172.20.20.13  (todo: fetch this from build_vagrant/conf/vagrant-cluster.json)
export HOSTING_ENV=lxd

# create zip file
rm -rf /tmp/hashi_common.zip
rm -rf /tmp/hashi_lxd.zip
cd "$HASHI_COMMON_REPO_DIRECTORY"
zip -r "/tmp/hashi_common.zip" ./build/ ./services/ ./utilities/ -x "*.pyc" -x "__pychache__/" -x "./services/vault/init/tls-certs/*terraform*"
cd "$HASHI_LXD_REPO_DIRECTORY"
zip -r "/tmp/hashi_lxd.zip" ./build_lxd/ansible/ ./build_lxd/conf/


# create tls certs for Vault
# -----------------------------------------
VAULT_IPS=$(cat "$INSTANCE_CONFIG_FP" | jq -r '[.[] | select(.node_type == "vault") | .ip] | join(" ")')
if [[ ! -f "/tmp/ansible-data/vault-tls-certs.zip" ]]; then
  $HASHI_COMMON_REPO_DIRECTORY/services/vault/init/tls-certs/create_vault_tls_certs.sh $VAULT_IPS
fi
# -----------------------------------------


cd "$HASHI_LXD_REPO_DIRECTORY/build_lxd/infrastructure"
if [ ! -f "./terraform.tfstate" ]; then
  echo "running terraform init"
  terraform init
fi

terraform destroy -auto-approve
terraform apply -auto-approve \
  -var="hashi_lxd_repo_directory=$HASHI_LXD_REPO_DIRECTORY" \
  -var="hashi_common_repo_directory=$HASHI_COMMON_REPO_DIRECTORY"


#vagrant ssh hashi-server-1 -c "cd /scripts/build/ansible; ./bootstrap_cluster_services.sh"
