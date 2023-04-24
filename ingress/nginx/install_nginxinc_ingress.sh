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
# https://artifacthub.io/packages/helm/bitnami/nginx-ingress-controller
#
# Author: Justin Cook

set -o errexit

# shellcheck source=/dev/null
. env.sh

# Clone the NGINX controller repository for CRDs and Helm deployments

cd "${K8STMPDIR}"
#shellcheck disable=SC2064
trap "cd ${OLDPWD}" EXIT

if [ -d "kubernetes-ingress" ]
then
    cd kubernetes-ingress
    git pull origin v3.1.0
    cd ..
else
    git clone https://github.com/nginxinc/kubernetes-ingress.git --branch v3.1.0
fi
cd kubernetes-ingress/deployments/helm-chart

#https://github.com/nginxinc/kubernetes-ingress/issues/3714
#    --set controller.hostNetwork=true \ 
# https://github.com/nginxinc/kubernetes-ingress/releases
helm upgrade --install ingress-nginx . \
    --set controller.installCRDs=true \
    --set nameOverride=ingress-nginx \
    --set rbac.create=true \
    --namespace ingress-nginx \
    --create-namespace

# Wait for NGINX to become available
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx