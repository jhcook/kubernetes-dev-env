#!/usr/bin/env sh
#
# These are entries to modify the environment for code in this repository.
#
# Author: Justin Cook

# Changes in versioning with an independently installed kubectl utility can
# cause unexpected outcomes with API access. The assumption is Kubernetes is on
# Minikube, but if the calico profile is not found, use kubectl in PATH.
if which minikube && minikube status -p calico
then
  alias kubectl="minikube kubectl -p calico --"
fi >/dev/null 2>&1
