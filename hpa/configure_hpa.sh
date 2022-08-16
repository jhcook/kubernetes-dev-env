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
# Configure HPA using Keda 
#
# References:
# * https://www.nginx.com/blog/microservices-march-reduce-kubernetes-latency-with-autoscaling/
# * https://stackoverflow.com/questions/62578789/kubectl-patch-is-it-possible-to-add-multiple-values-to-an-array-within-a-sinlge
#
# Requires: jq, yq
#
# Author: Justin Cook

set -o errexit nounset

# shellcheck source=/dev/null
. env.sh

# Add the Keda Helm chart repository
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

# Create the keda namespace 
kubectl create namespace keda --dry-run=client -o yaml | \
  kubectl apply -f -

# Install Keda
helm upgrade --install keda kedacore/keda --namespace keda

# Wait for all the deployments to become available
for deploy in $(kubectl get deploy -n keda -o name)
do
  kubectl rollout status "${deploy}" -n keda
done

# Create an Ingress for the Boutique®
kubectl apply -f hpa/frontend-ingress.yaml -n "${PROJECT_NAMESPACE}"
