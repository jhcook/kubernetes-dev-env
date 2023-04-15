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
# Install Prometheus, Grafana, and configure the monitoring stack
#
# Resources:
#  * http://charts.rancher.io/index.yaml
#  * https://github.com/rancher/charts/tree/release-v2.7/charts/rancher-monitoring-crd
#  * https://github.com/rancher/charts/tree/release-v2.7/charts/rancher-monitoring
#
# Author: Justin Cook

set -o errexit

# shellcheck source=/dev/null
. env.sh

# Add the applicable Helm chards to the repo and update
helm repo add rancher-monitoring-crd http://charts.rancher.io
helm repo add rancher-monitoring http://charts.rancher.io
helm repo update

# Install the required charts for rancher-monitoring which is just upstream
# Prometheus and Grafana operators et al with a bit of configuration
helm upgrade --install=true --timeout=10m0s --wait=true \
  --values=https://raw.githubusercontent.com/rancher/charts/release-v2.7/charts/rancher-monitoring-crd/102.0.0%2Bup40.1.2/values.yaml \
  --version=102.0.0+up40.1.2 \
  --namespace=cattle-monitoring-system \
  --create-namespace \
  rancher-monitoring-crd \
  http://charts.rancher.io/assets/rancher-monitoring-crd/rancher-monitoring-crd-102.0.0+up40.1.2.tgz

helm upgrade --install=true --timeout=10m0s --wait=true \
  --values=https://raw.githubusercontent.com/rancher/charts/release-v2.7/charts/rancher-monitoring/102.0.0%2Bup40.1.2/values.yaml \
  --version=102.0.0+up40.1.2 \
  --namespace=cattle-monitoring-system \
  rancher-monitoring \
  http://charts.rancher.io/assets/rancher-monitoring/rancher-monitoring-102.0.0+up40.1.2.tgz

# Wait for all the deployments to become available
for deploy in $(kubectl get deploy -n cattle-monitoring-system -o name)
do
  kubectl rollout status "${deploy}" -n cattle-monitoring-system
done