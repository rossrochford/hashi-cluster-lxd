#!/bin/bash

export GOSSIP_ENCRYPTION_KEY="sdfs9dssf87sdf"
export ANSIBLE_REMOTE_USER=ubuntu


ansible-playbook /home/ross/code/hashi-cluster/hashi-cluster-common/build/ansible/playbooks/init/consul/set-gossip-encryption-key.yml

#ansible all -m ping
