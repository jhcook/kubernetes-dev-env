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
# Configure sidecar and init container for custom metrics 
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

# Configure Docker image to use appropriate image name
if ! ${IGNORE_DOCKER_CONFIG}
then
  IMAGE_REGISTRY="localhost:${DOCKER_REG_PORT}/boutique/"
else
  IMAGE_REGISTRY=""
fi

# Patch each deployment with custom exporter to make metrics available via
# Prometheus. Patch the cooresponding service to include said endpoint
# then follow up by creating a ServiceMonitor. Give yourself a pat on the back,
# Prometheus is now collecting metrics from your clever exporter.
for deploy in $(kubectl get deploy -n "${PROJECT_NAMESPACE}" -o name | grep -E 'service$')
do
  # shellcheck disable=SC2086
  SVCPORT="$(kubectl get svc ${deploy#*/} -n ${PROJECT_NAMESPACE} -o \
             jsonpath='{.spec.ports[-1].port}' 2>/dev/null)" || continue
  
  printf "Patching service %s with TCP %s\n" "${deploy#*/}" "${SVCPORT}"
  kubectl patch svc "${deploy#*/}" -n "${PROJECT_NAMESPACE}" \
  -p='{"spec": {"type": "ClusterIP","ports": [{"name": "prometheus","port": 9100,"protocol": "TCP","targetPort": 9100}]}}'

  kubectl patch svc "${deploy#*/}" -n "${PROJECT_NAMESPACE}" \
  -p="{\"metadata\": {\"labels\": {\"k8s-app\": \"${deploy#*/}\"}}}"

  printf "Patching %s\n" "${deploy}"

  # Create a JSON patch for the tcp-exporter container
  TEPATCH=$(yq -o json -I0 <<-EOF
name: tcp-exporter
image: "${IMAGE_REGISTRY}tcp-exporter:latest"
imagePullPolicy: Always
securityContext:
  capabilities:
    drop:
    - all
    add:
    - NET_ADMIN
args: ["9100", "${SVCPORT}"]
ports:
  - containerPort: 9100
    protocol: TCP
EOF
)

  # Create a JSON patch for the conntrack init container
  CIPATCH=$(yq -o json -I0 <<-EOF
name: init-networking
image: "${IMAGE_REGISTRY}conntrack-network-init:latest"
resources: {}
terminationMessagePath: /dev/termination-log
terminationMessagePolicy: File
imagePullPolicy: Always
securityContext:
  capabilities:
    drop:
    - all
    add:
    - NET_ADMIN
    - NET_RAW
    - DAC_READ_SEARCH
    - DAC_OVERRIDE
EOF
)

  # Apply the tcp-exporter and init container patches and enable shared process
  # namespace
  kubectl get "${deploy}" -n "${PROJECT_NAMESPACE}" -o json | \
    jq ".spec.template.spec.containers[1] = ${TEPATCH}" | \
    jq ".spec.template.spec.initContainers[0] = ${CIPATCH}" | \
    jq '.spec.template.spec.shareProcessNamespace = true' | \
    kubectl apply -f -

  # Apply the ServiceMonitor to enable Prometheus scraping
  # working:   namespace: ${PROMETHEUS_NS}
  kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: boutique-${deploy#*/}-prometheus-config
  namespace: "${PROJECT_NAMESPACE}"
spec:
  selector:
    matchLabels:
      k8s-app: "${deploy#*/}"
  namespaceSelector:
    matchNames:
    - "${PROJECT_NAMESPACE}"
  endpoints:
  - path: /metrics
    port: prometheus
    interval: 10s
EOF
done