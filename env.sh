#!/usr/bin/env bash
#
# Copyright 2022 Justin Cook
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# These are entries to modify the environment for code in this repository.
#
# Author: Justin Cook

# Check if all the necessary utilities are available or exit
# `kubectl` is unnecessary in this context as it is later aliased to minikube
for cmd in "minikube" "helm" "git" "virtualenv" "yq" "jq"
do
  if ! command -v "${cmd}" &> /dev/null
  then
      echo "command: ${cmd} could not be found"
      exit 1
  fi
done

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
