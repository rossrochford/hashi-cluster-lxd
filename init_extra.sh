# todo: append this to initialize_hashi_cluster.sh


# for some reason, Traefik isn't getting started by the ansible playbook? So retry it here.
sleep 2
vagrant ssh traefik-1 -c 'nomad job run /etc/traefik/traefik.nomad'  #> /dev/null 2>&1

rm -rf /tmp/ansible-data/vault-tls-certs.zip



PING_URL="http://traefik.localhost:8085/ping"

for run in {1..40}
do
  echo "attempting request to: $PING_URL"
  STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}"  $PING_URL)
  if [[ "$STATUS_CODE" == "200" ]]; then
    echo ""
    echo "Ping success! Your cluster is up and running."
    exit 0
  fi
  sleep 8
done

echo "warning: connecting to traefik timed out"


# to clear vagrant cache run:
# rm -rf ~/.vagrant.d/boxes/*
# rm -rf ~/VirtualBox\ VMs/*
