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
# Install the Tigera Calico operator and deploy Calico CNI
# Watch pods until calico-kube-controllers is deployed
#
# Requires: kubectl
#
# Author: Justin Cook

set -o errexit

# shellcheck source=/dev/null
. env.sh

CALICOSOURCE="https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml"

# Install Tigera operator. In order to compensate for previous runs, remove the
# previous applied resources. This is not ideal, but Calico uses more space for
# CRDs than is allowed by apply.
# TODO: switch to Helm install https://docs.tigera.io/calico/latest/getting-started/kubernetes/helm
kubectl create -f ${CALICOSOURCE} --dry-run=client -o yaml | \
kubectl delete -f - || /usr/bin/true

kubectl create -f ${CALICOSOURCE}

# Wait on the operator to run
kubectl rollout status deploy/tigera-operator -n tigera-operator

# Install Calico using Installation kind
cat <<EOF | kubectl apply -f -
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    containerIPForwarding: Enabled
    ipPools:
    - blockSize: 26
      cidr: ${POD_NET_CIDR}
      natOutgoing: Enabled
      encapsulation: VXLANCrossSubnet
      nodeSelector: all()
  typhaMetricsPort: 9093

---

# This section configures the Calico API server.
# For more information, see: https://projectcalico.docs.tigera.io/v3.22/reference/installation/api#operator.tigera.io/v1.APIServer
apiVersion: operator.tigera.io/v1
kind: APIServer 
metadata: 
  name: default 
spec: {}
EOF

# Wait until the Installation is progressing
while :
do
  kubectl get tigerastatus/calico 2>/dev/null && break
  sleep 1
done

# Display pods until calico-kube-controllers rolls out
kubectl get pods -A -w &
watch_pid="$!"

# Wait on calico-kube-controllers deployment
kubectl rollout status deploy/calico-kube-controllers -n calico-system

kill -15 ${watch_pid}
wait ${watch_pid} || /usr/bin/true
