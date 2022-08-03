#!/usr/bin/env bash
#
# Copyright 2022 Justin Cook and Kind Authors
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
# Get a kind cluster up and running with Colima and internal registry.
#
# References:
#   * https://kind.sigs.k8s.io/docs/user/local-registry/
#   * https://github.com/abiosoft/colima
#
# Requires:
#   * colima
#   * kind
#   * kubectl

set -o errexit
shopt -s expand_aliases

# Setup Colima
# This should already exist with kind cluster due to below issue
# https://github.com/containerd/nerdctl/issues/349
# --runtime containerd
colima start --cpu 6 --memory 28 --disk 100

# Alias docker to use lima nerdctl
colima nerdctl install
ln -s "$(which nerdctl)" docker
PATH="$(pwd):$PATH"
export PATH

if ! grep 'alias docker="nerdctl"' "${HOME}/.bash_aliases" 2>/dev/null
then
  echo 'alias docker="nerdctl"' >> "${HOME}/.bash_aliases"
fi
# shellcheck source=/dev/null
source "${HOME}/.bash_aliases"

# Wait on docker
echo -n "Waiting on docker"
while :
do
  docker ps >/dev/null 2>&1 && break
  echo -n "."
  sleep 2
done
echo

# Create a registry container unless it already exists
reg_name='kind-registry'
reg_port='5001'
if [ "$(docker inspect -f '{{.State.Running}}' \"${reg_name}\")" != 'true' ]
then
  docker run -d --restart=always -p "127.0.0.1:${reg_port}:5000" \
    --name "${reg_name}" registry:2
fi

# Create the kind cluster
# https://github.com/containerd/nerdctl/issues/349
kind create cluster --config kind/calico_cluster.yaml

# connect the registry to the cluster network if not already connected
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' \"${reg_name}\")" = 'null' ]
then
  docker network connect "kind" "${reg_name}"
fi

# Document the local registry
# https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF