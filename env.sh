#!/usr/bin/env bash
#
# These are entries to modify the environment for code in this repository.
#
# Author: Justin Cook

# Pod network CIDR
export POD_NET_CIDR="172.16.0.0/16"

# Changes in versioning with an independently installed kubectl utility can
# cause unexpected outcomes with API access. The assumption is Kubernetes is on
# Minikube, but if the calico profile is not found, use kubectl in PATH.
#
# The else clause is left commented as it's for special development use cases.
if which minikube && minikube status
then
  alias kubectl="minikube kubectl --"
#else
#  alias kubectl="kubectl --kubeconfig=kubeconfig --insecure-skip-tls-verify=true"
fi >/dev/null 2>&1
