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
# Install Kubernetes community supported NGINX ingress controller
# https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx
# https://learn.microsoft.com/en-us/azure/aks/ingress-basic?tabs=azure-cli
# https://docs.rancherdesktop.io/how-to-guides/setup-NGINX-Ingress-Controller
# https://artifacthub.io/packages/helm/bitnami/nginx-ingress-controller
#
# Author: Justin Cook

set -o errexit

# shellcheck source=/dev/null
. env.sh

# Clone the NGINX controller repository for CRDs and Helm deployments

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install the Helm chart
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --set controller.hostNetwork=true \
    --namespace ingress-nginx \
    --create-namespace

# Wait for NGINX to become available
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx