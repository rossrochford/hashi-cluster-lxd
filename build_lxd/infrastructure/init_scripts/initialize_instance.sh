#!/bin/bash

#mkdir -p /home/ubuntu/.tmp-ansible/
#chmod 0777 -R /home/ubuntu/.tmp-ansible/
#chown -R ubuntu:ubuntu /home/ubuntu/.tmp-ansible/
mkdir -p /tmp/ansible-data/
chmod 0777 -R /tmp/ansible-data/

mkdir -p /scripts
unzip -o /home/ubuntu/hashi_common.zip -d /scripts
unzip -o /home/ubuntu/hashi_lxd.zip -d /scripts
mv /home/ubuntu/vault-tls-certs.zip /tmp/ansible-data/vault-tls-certs.zip


chmod 600 /root/.ssh/id_ed25519_lxd
chmod 644 /root/.ssh/id_ed25519_lxd.pub
cat /root/.ssh/id_ed25519_lxd.pub >> /root/.ssh/authorized_keys

chmod 600 /home/ubuntu/.ssh/id_ed25519_lxd
chmod 644 /home/ubuntu/.ssh/id_ed25519_lxd.pub
cat /home/ubuntu/.ssh/id_ed25519_lxd.pub >> /home/ubuntu/.ssh/authorized_keys


#source /etc/environment
#export $(grep -v '^#' /etc/environment | xargs)


export HOSTING_ENV=lxd
export INSTANCE_CONFIG_FILEPATH="/scripts/build_lxd/conf/lxd-instances.json"
export PROJECT_INFO_FILEPATH="/scripts/build_lxd/conf/project-info.json"

CLUSTER_PROJECT_ID=$(/scripts/utilities/metadata_get "cluster_service_project_id")
export CTN_PREFIX="hashi-cluster-nodes/$NODE_NAME"
export CTP_PREFIX="hashi-cluster-projects/$CLUSTER_PROJECT_ID"
export PYTHONPATH=/scripts/utilities

# todo: move back to common?
{
  echo "HOSTING_ENV=$HOSTING_ENV"
  echo "INSTANCE_CONFIG_FILEPATH=$INSTANCE_CONFIG_FILEPATH"
  echo "PROJECT_INFO_FILEPATH=$PROJECT_INFO_FILEPATH"
  echo "NODE_IP=\"$NODE_IP\""
  echo "NODE_NAME=\"$NODE_NAME\""
  echo "NODE_TYPE=\"$NODE_TYPE\""
  echo "CLUSTER_PROJECT_ID=\"$CLUSTER_PROJECT_ID\""
  echo "CTN_PREFIX=\"$CTN_PREFIX\""
  echo "CTP_PREFIX=\"$CTP_PREFIX\""
  echo "PYTHONPATH=$PYTHONPATH"
  echo "HOSTING_ENV=$HOSTING_ENV"
  echo "INSTANCE_CONFIG_FILEPATH=$INSTANCE_CONFIG_FILEPATH"
  echo "PROJECT_INFO_FILEPATH=$PROJECT_INFO_FILEPATH"
} >> /etc/environment


/scripts/build/vm_image/init_scripts/initialize_instance__common.sh
