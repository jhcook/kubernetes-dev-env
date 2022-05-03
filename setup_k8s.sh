#!/usr/bin/env bash
#
# Setup a three-node Kubernetes cluster with ingress, ingress-dns, and
# metrics-server with CNI plugin. Configure the pod network as ${POD_NET_CIDR}.
# Use Kubernetes v1.23.4 as that is latest supported by Rancher. Finally, set
# resolver to forward .test DNS queries to this cluster.
#
# This code needs permissions to configure DNS accordingly. It uses `sudo` to
# make the necessary changes. The commands needing elevated permissions vary
# by platform.
#
# If you are on Linux with NetworkManager, the changes aren't something to
# worry about. Otherwise, the code assumes dnsmasq is available and attempts to
# configure as necessary.
#
# Author: Justin Cook

# shellcheck source=/dev/null
. env.sh

# The below options can be used with a docker provider such as lima/colima.
#         --driver=docker \
#         --cache-images=true \
#         --container-runtime=containerd \

minikube --addons=ingress,ingress-dns,metrics-server,registry \
         --insecure-registry="10.0.0.0/24" \
         --network-plugin=cni \
         --extra-config="kubeadm.pod-network-cidr=${POD_NET_CIDR}" \
         --service-cluster-ip-range='10.96.0.0/16' \
         --memory=8g \
         --kubernetes-version=v1.23.4 \
         --nodes=3 \
         --insecure-registry="ghcr.io","k8s.gcr.io","gcr.io" \
         start

if [ ! -d "/etc/resolver" ]
then
  sudo mkdir /etc/resolver
fi

PLATFORM=$(uname)
case ${PLATFORM} in
  Darwin)
    printf "Configuring macOS to forward .test to Minikube\n"
    sudo bash -c "cat - > /etc/resolver/minikube-test <<EOF
domain test
nameserver $(minikube ip)
search_order 1
timeout 5
EOF
"
    ;;
  Linux)
    printf "Configuring Linux to forward .test to Minikube\n"
    # Check and see if NetworkManager is installed and running
    if which NetworkManager && sudo systemctl status NetworkManager.service
    then
      if ! grep -q ^dns=dnsmasq$ /etc/NetworkManager/NetworkManager.conf
      then
        sudo sed '/^\[main\]$/a dns=dnsmasq' /etc/NetworkManager/NetworkManager.conf
        if [ ! -d "/etc/NetworkManager/dnsmasq.d" ]
        then
          sudo mkdir /etc/NetworkManager/dnsmasq.d
        fi
        sudo bash -c "echo \"server=/test/$(minikube ip)\" > \
          /etc/NetworkManager/dnsmasq.d/minikube.conf"
        sudo systemctl restart NetworkManager.service
      fi
    elif which resolvconf && systemctl status resolvconf.service
    then
      sudo bash -c "cat - > /etc/resolvconf/resolv.conf.d/base <<EOF
search test
nameserver $(minikube ip)
timeout 5
EOF
"
      sudo resolvconf -u
      sudo systemctl disable --now resolvconf.service
    else
      printf "Unknown Linux resolver configuration\n" 1>&2
      printf "Please configure .test resolution to Minikube\n" 1>&2
    fi >/dev/null
    ;;
  *)
    printf "Unknown platform: %s" "${PLATFORM}\n" 1>&2
    printf "Unable to configure .test resolution\n" 1>&2
    exit 255
    ;;
esac
