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
# Install Online Boutique for Kubernetes sample and load testing
#
# Author: Justin Cook

set -o errexit

# shellcheck source=/dev/null
. env.sh

ORIG_WRK_DIR="$(pwd)"

# Check if the virtualenv exists. If not, create it.
if [ ! -d "${K8STMPDIR}/venv-locust" ]
then
  virtualenv "${K8STMPDIR}/venv-locust"
fi

# Activate the virtualenv and install locust
# shellcheck source=/dev/null
source "${K8STMPDIR}/venv-locust/bin/activate"
pip install locust

# Check if the boutique, aka microservices-demo, exists. If not, clone it.
cd "${K8STMPDIR}"
if [ ! -d "microservices-demo" ]
then
  git clone https://github.com/GoogleCloudPlatform/microservices-demo.git
  cd microservices-demo
else
  cd microservices-demo
  git pull
fi

# Install the boutique.
kubectl apply -f ./release/kubernetes-manifests.yaml

# Wait for the boutique to become available.
for deploy in $(kubectl get deploy -n default -o name)
do 
  kubectl rollout status "${deploy}"
done

kubectl apply -f "${ORIG_WRK_DIR}/app/frontend-ingress.yaml"
kubectl annotate ingress frontend-ingress kubernetes.io/ingress.class=nginx \
  --overwrite=true --dry-run=client -o yaml | kubectl apply -f -

if [ "${RUNTIME}" != "minikube" ]
then
  printf "\nPlease configure name resolution boutique.test to master's IP.\n"
fi

printf "\nOpen browser to: http://boutique.test\n\n"

# Run locust
cd src/loadgenerator || exit
locust