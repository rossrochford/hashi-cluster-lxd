#!/bin/bash

if [ -f "../../.env" ]; then
  source "../../.env"
fi

if [[ -z $HASHI_COMMON_REPO_DIRECTORY ]]; then
  echo "error: HASHI_COMMON_REPO_DIRECTORY env variable must be set"; exit 1
fi

if [[ -z $HASHI_LXD_REPO_DIRECTORY ]]; then
  echo "error: HASHI_LXD_REPO_DIRECTORY env variable must be set"; exit 1
fi


export ANSIBLE_REMOTE_USER=ubuntu
export HOSTING_ENV=lxd
INSTANCE_CONFIG_FP="$HASHI_LXD_REPO_DIRECTORY/build_lxd/conf/lxd-instances.json"


run_playbook () {
  if [[ "$1" == "lxd" && $HOSTING_ENV != "lxd" ]]; then
    return 0
  fi
  ansible-playbook "$HASHI_COMMON_REPO_DIRECTORY/build/ansible/playbooks/init/$1/$2"
  if [[ $? != 0 ]]; then
    echo "playbook $1/$2 failed, exiting bootstrap_cluster_services__lxd.sh"; exit 1
  fi
}


export CONSUL_BOOTSTRAP_TOKEN=$(cat /tmp/ansible-data/consul-bootstrap-token.json | jq -r ".SecretID")
export CONSUL_HTTP_TOKEN=$CONSUL_BOOTSTRAP_TOKEN



# after ACL bootstrapping is complete, configure the anonymous token policy
run_playbook consul configure-anonymous-token.yml  #/scripts/services/consul/init/configure_anonymous_token.sh



# Register nodes with Consul KV  - used by consul-template on Vault and Nomad config files
# -----------------------------------------

sleep 15
run_playbook consul register-nodes-with-consul-kv.yml



# Initialize Vault
# ---------------------

if [[ $HOSTING_ENV == "lxd" ]]; then
  export VAULT_IP_ADDRS=$(cat "$INSTANCE_CONFIG_FP" | jq -r '[.[] | select(.node_type == "vault") | .ip] | join(" ")')
else
  export VAULT_IP_ADDRS=$(go_discover vault-server)
fi

if [[ $(check_exists "env" "VAULT_IP_ADDRS") == "no" ]]; then echo "error: no vault servers found by go_discover"; exit 1; fi
export VAULT_IP_ADDR_1=$(echo $VAULT_IP_ADDRS | cut -d' ' -f1)


run_playbook vault initialize-vault.yml

run_playbook lxd fetch-token-files.yml


NOMAD_VAULT_TOKENS_FILEPATH="/tmp/ansible-data/nomad-vault-tokens.json"
if [[ $(check_exists "file" $NOMAD_VAULT_TOKENS_FILEPATH) == "no" ]]; then echo "error: missing nomad-vault-tokens.json"; exit 1; fi
export NOMAD_VAULT_TOKENS=$(cat $NOMAD_VAULT_TOKENS_FILEPATH)



# Initialize Nomad
# ----------------------

run_playbook nomad initialize-nomad.yml



# Add read-only tokens to /etc/environment on each node, with a special token for hashi-server-1
# --------------------------------------------

echo "setting agent tokens for shell"
run_playbook consul set-agent-tokens-for-shell.yml



# Initialize Traefik (note: set-agent-tokens-for-shell.yml should preceed this because traefik/init/launch_config_watcher.sh uses the consul agent token)
# ------------------------------

run_playbook traefik initialize-traefik.yml



# create zip file of tokens
# ---------------------------------
# PASSWORD=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/id)
# zip --password $PASSWORD -r /tmp/ansible-data.zip /tmp/ansible-data > /dev/null



# print out tokens
# ----------------------------------
CONSUL_UI_TOKEN_RW=$(cat /tmp/ansible-data/consul-ui-token-rw.json | jq -r ".SecretID")
CONSUL_UI_TOKEN_RO=$(cat /tmp/ansible-data/consul-ui-token-ro.json | jq -r ".SecretID")
VAULT_ROOT_TOKEN=$(cat /tmp/ansible-data/vault-root-token.txt)
VAULT_WRITEONLY_TOKEN=$(cat /tmp/ansible-data/vault-writeonly-token.txt)
VAULT_UNSEAL_KEY=$(cat /tmp/ansible-data/vault-unseal-key.txt)


echo "-----------------------------------------------------------"

echo ""
echo "consul bootstrap token:                         $CONSUL_BOOTSTRAP_TOKEN"
echo "consul gossip encryption key:                   $GOSSIP_ENCRYPTION_KEY"

echo ""
echo "consul UI token (read/write):                   $CONSUL_UI_TOKEN_RW"
echo "consul UI token (read-only):                    $CONSUL_UI_TOKEN_RO"

echo ""
echo "vault root token:                               $VAULT_ROOT_TOKEN"
echo "vault write-only token:                         $VAULT_WRITEONLY_TOKEN"

if [[ $VAULT_UNSEAL_KEY != "none" ]]; then
  echo "vault unseal key:                               $VAULT_UNSEAL_KEY"
fi
