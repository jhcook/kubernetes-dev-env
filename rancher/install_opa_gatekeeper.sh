#!/usr/bin/env bash
#
# Copyright 2023 Justin Cook
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
# Install OPA Gatekeeper using Rancher's Helm chart. It modifies Open Policy
# Agent's upstream gatekeeper chart that provides policy-based control for
# cloud native environments.
#
# Author: Justin Cook

set -o errexit

# shellcheck source=/dev/null
. env.sh

# Add the applicable Helm chards to the repo and update
helm repo add rancher-gatekeeper-crd http://charts.rancher.io
helm repo add rancher-gatekeeper http://charts.rancher.io
helm repo update

# Install the required charts for OPA Gatekeeper and CRDs
helm upgrade --install=true --timeout=10m0s --wait=true \
  --values=https://raw.githubusercontent.com/rancher/charts/release-v2.7/charts/rancher-gatekeeper-crd/101.0.0%2Bup3.9.0/values.yaml \
  --namespace=cattle-gatekeeper-system \
  --create-namespace \
  --version=101.0.0+up3.9.0 \
  rancher-gatekeeper-crd \
  http://charts.rancher.io/assets/rancher-gatekeeper-crd/rancher-gatekeeper-crd-101.0.0+up3.9.0.tgz

helm upgrade --install=true --timeout=10m0s --wait=true \
  --values=https://raw.githubusercontent.com/rancher/charts/release-v2.7/charts/rancher-gatekeeper/101.0.0%2Bup3.9.0/values.yaml \
  --version=101.0.0+up3.9.0 \
  --namespace=cattle-gatekeeper-system \
  rancher-gatekeeper \
  http://charts.rancher.io/assets/rancher-gatekeeper/rancher-gatekeeper-101.0.0+up3.9.0.tgz

# Wait for all the deployments to become available
for deploy in $(kubectl get deploy -n cattle-gatekeeper-system -o name)
do
  kubectl rollout status "${deploy}" -n cattle-gatekeeper-system
done