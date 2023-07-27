#!/usr/bin/env bash
#
# Support for Windows hosts. 
#
# Prerequisites: 
# 1) In order to take full advantage of ingress-dns, Windows hosts 
# require the ability to forward DNS traffic to Minikube for resolution. It is
# known YogaDNS provides this capability, and manual configuration should be
# applied after creation of the Minikube cluster.
#
# 2) This configuration uses existing Vagrant boxes and as such is intended to
# be provided the following information:
#
# Tested on: Windows 11
#
# Author: Justin Cook

# shellcheck source=/dev/null
. env.sh

set -o errexit nounset
VDIR="$(pwd)/vagrant/.vagrant"
HOST_LINES=$(sed -n '/^.*__HOSTS__$/,/^__HOSTS__$/p' vagrant/hyperv_hosts.sh)

while IFS=$'\t' read -r ip node
do
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
    then
        n="${node}"
        echo "$n: $ip"
        if grep -q "${n}" /c/Windows/System32/drivers/etc/hosts
        then
            sed -i -E "s/^[0-9.]+\\s+${n}$/${ip}\\t${n}/" /c/Windows/System32/drivers/etc/hosts
        else
            printf "%s\\t%s\\n" "${ip}" "${n}" | tee -a /c/Windows/System32/drivers/etc/hosts
        fi
        if [ "${n}" = "master" ]
        then #                     --container-runtime=containerd \
            #shellcheck disable=SC2140
            minikube --driver=ssh --ssh-user="vagrant" --ssh-ip-address="${ip}" --native-ssh=false \
                     --ssh-key="$VDIR/machines/master/hyperv/private_key" \
                     --addons=ingress,ingress-dns,metrics-server,registry \
                     --insecure-registry="10.0.0.0/24" \
                     --network-plugin=cni \
                     --extra-config="kubeadm.pod-network-cidr=${POD_NET_CIDR}" \
                     --service-cluster-ip-range="${SERVICECLUSTERIPRANGE}" \
                     --kubernetes-version=v1.26.4 \
                     --insecure-registry="ghcr.io","registry.k8s.io","k8s.gcr.io","gcr.io" \
                     -v=2 --alsologtostderr \
                     start
        else
            minikube --driver=ssh --ssh-user="vagrant" --ssh-ip-address="${ip}" --native-ssh=false \
                     --ssh-key="$VDIR/machines//hyperv/private_key" \
                     node add
        fi
    fi
done < <(echo "$HOST_LINES")

echo "configure resolution for .test to: $(minikube ip)"
