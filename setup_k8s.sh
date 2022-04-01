#!/usr/bin/env bash
#
# Setup a three-node Kubernetes cluster with ingress, ingress-dns, and
# metrics-server with CNI plugin. Configure the pod network as 172.16.0.0/20.
# Use Kubernetes v1.23.4 as that is latest supported by Rancher. Finally, set
# resolver to forward .test DNS queries to this cluster.
#
# Author: Justin Cook

minikube --addons ingress,ingress-dns,metrics-server,registry \
         --insecure-registry "10.0.0.0/24" \
         --network-plugin=cni \
         --extra-config=kubeadm.pod-network-cidr=172.16.0.0/20 \
         --memory=8g \
         --kubernetes-version=v1.23.4 \
         --nodes=3 \
         --insecure-registry="ghcr.io" \
         -p calico \
         start

if [ ! -d "/etc/resolver" ]
then
  sudo mkdir /etc/resolver
fi

sudo bash -c "cat - > /etc/resolver/minikube-test <<EOF
domain test
nameserver $(minikube ip -p calico)
search_order 1
timeout 5
EOF
"