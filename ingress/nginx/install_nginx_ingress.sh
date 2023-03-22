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
# Install NGINX ingress controller
# https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/
# https://docs.rancherdesktop.io/how-to-guides/setup-NGINX-Ingress-Controller
#
# Author: Justin Cook

set -o errexit

# shellcheck source=/dev/null
. env.sh

ORIG_WRK_DIR="${PWD}"
THIS_WRK_DIR="ingress/nginx"

# Clone the NGINX controller repository for CRDs

cd "${THIS_WRK_DIR}"
if [ -d "kubernetes-ingress" ]
then
    cd kubernetes-ingress
    git pull origin v3.0.2
    cd ..
else
    git clone https://github.com/nginxinc/kubernetes-ingress.git --branch v3.0.2
    #cd kubernetes-ingress/deployments/helm-chart
fi

# Ignore the cloned directory above with this repo's git.
if ! grep "^${THIS_WRK_DIR}/kubernetes-ingress$" "${ORIG_WRK_DIR}/.gitignore"
then
    #shellcheck disable=SC2086
    if [ -n "$(tail -c1 ${ORIG_WRK_DIR}/.gitignore)" ]
    then
        echo "" >> "${ORIG_WRK_DIR}/.gitignore"
    fi
    echo "${THIS_WRK_DIR}/kubernetes-ingress" >> "${ORIG_WRK_DIR}/.gitignore"
fi

if [ "${RUNTIME}" = "rdctl" ]
then
    helm upgrade --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress-nginx --create-namespace
else
    # Add the helm repo
    helm repo add nginx-stable https://helm.nginx.com/stable
    helm repo update

    # Install the chart from the NGINX chart repository
    helm upgrade --install nginx-ingress nginx-stable/nginx-ingress \
         --set rbac.create=true \
         --namespace ingress-nginx \
         --create-namespace
fi

# Wait for NGINX to become available
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx