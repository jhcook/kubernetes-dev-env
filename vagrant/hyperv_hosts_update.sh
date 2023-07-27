#!/usr/bin/env bash

set -x
cd vagrant

# Now we have running boxes do post configuration as Hyperv is limited
# https://developer.hashicorp.com/vagrant/docs/providers/hyperv/limitations
RUNNING_MACHINES="$(vagrant status | awk '$2 == "running" {print$1}')"
#RUNNING_MACHINES=(master node1 node2)
#IPS=(1.1.2.2 2.3.2.3 3.3.3.4)

for machine in ${RUNNING_MACHINES}
#for ((i=0; i<${#RUNNING_MACHINES[@]}; i++))
do
  IP="$(vagrant ssh-config "${machine}" | awk '/HostName/{print$2}')"
  #machine="${RUNNING_MACHINES[i]}"
  #IP="${IPS[i]}"

  if awk 'BEGIN {rc=1} /__HOSTS__/{f=1;next} f && /__HOSTS__/{exit} f && /[0-9.]+\t'"${machine}"'/{print "found"; rc=0; exit} END {exit rc}' hyperv_hosts.sh
  then
    sed -i -E "s/^[0-9.]+\\s+${machine}$/${IP}\\t${machine}/" hyperv_hosts.sh
  else
    sed -i "/^__HOSTS__$/i\\
${IP}\\t${machine}
" hyperv_hosts.sh
  fi
done
