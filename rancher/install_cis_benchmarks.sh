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
# Install Prometheus, Grafana, and configure the monitoring stack
#
# Resources:
#  * http://charts.rancher.io/index.yaml
#  * https://github.com/rancher/charts/tree/dev-v2.7/charts/rancher-cis-benchmark-crd
#  * https://github.com/rancher/charts/tree/dev-v2.7/charts/rancher-cis-benchmark
#
# Author: Justin Cook

set -o errexit

# shellcheck source=/dev/null
. env.sh

# Add the applicable Helm charts to the repo and update
helm repo add rancher-cis-benchmark-crd http://charts.rancher.io
helm repo add rancher-cis-benchmark http://charts.rancher.io
helm repo update

# Install CIS Benchmark with CRDs
helm upgrade --install=true --namespace=cis-operator-system --timeout=10m0s \
  --version=4.0.0 --create-namespace --wait=true rancher-cis-benchmark-crd \
  http://charts.rancher.io/assets/rancher-cis-benchmark-crd/rancher-cis-benchmark-crd-4.0.0.tgz

helm upgrade --install=true --namespace=cis-operator-system --timeout=10m0s \
  --values=https://raw.githubusercontent.com/rancher/charts/dev-v2.7/charts/rancher-cis-benchmark/4.0.0/values.yaml \
  --version=4.0.0 --wait=true rancher-cis-benchmark \
  http://charts.rancher.io/assets/rancher-cis-benchmark/rancher-cis-benchmark-4.0.0.tgz

# Wait for all the deployments to become available
for deploy in $(kubectl get deploy -n cis-operator-system -o name)
do
  kubectl rollout status "${deploy}" -n cis-operator-system
done