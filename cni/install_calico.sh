#!/usr/bin/env bash
#
# Copyright 2022-2023 Justin Cook
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
# Install the Tigera Calico Helm chart and deploy Calico CNI
# Watch pods until calico-kube-controllers is deployed
#
# Requires: kubectl
#
# https://docs.tigera.io/calico/latest/getting-started/kubernetes/helm
#
# Author: Justin Cook

set -o errexit

# shellcheck source=/dev/null
. env.sh

# Add the appropriate Helm repos and update
helm repo add projectcalico https://docs.tigera.io/calico/charts
helm repo update

# Create values.yaml
cat > "$(pwd)/cni/values.yaml" <<EOF
installation:
  cni:
    type: Calico
  calicoNetwork:
    ipPools:
    - blockSize: 26
      cidr: ${POD_NET_CIDR}
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
EOF

# Install Calico
helm upgrade --install calico projectcalico/tigera-operator \
  --version v3.25.1 \
  -f "$(pwd)/cni/values.yaml" \
  --namespace tigera-operator \
  --create-namespace

# Wait until the Installation is progressing
until kubectl get tigerastatus/calico >/dev/null 2>&1
do
  sleep 1
done

# Display pods until calico-kube-controllers rolls out
kubectl get pods -A -w &
watch_pid="$!"

# Wait on calico-kube-controllers deployment
until kubectl get deploy/calico-kube-controllers -n calico-system
do
  sleep 1
done
kubectl rollout status deploy/calico-kube-controllers -n calico-system

kill -15 ${watch_pid}
wait ${watch_pid} || /usr/bin/true
