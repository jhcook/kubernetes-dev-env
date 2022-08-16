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
# Configure HPA with Keda ScaledObjects 
#
# References:
# * https://www.nginx.com/blog/microservices-march-reduce-kubernetes-latency-with-autoscaling/
# * https://stackoverflow.com/questions/62578789/kubectl-patch-is-it-possible-to-add-multiple-values-to-an-array-within-a-sinlge
#
# Requires: kubectl
#
# Author: Justin Cook

set -o errexit nounset

# shellcheck source=/dev/null
. env.sh

# Create the ScaledObject(s)
PROMHOST=$(kubectl get svc "${PROMETHEUS_SVC}" -n \
           "${PROMETHEUS_NS}" -o jsonpath='{.spec.clusterIP}')

kubectl apply -f - <<EOF
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: recommendationservice-scale
  namespace: "${PROJECT_NAMESPACE}"
spec:
  scaleTargetRef:
    kind: Deployment
    name: recommendationservice
  minReplicaCount: 1
  maxReplicaCount: 20
  cooldownPeriod: 30
  pollingInterval: 1
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://${PROMHOST}:${PROMPORT}
      metricName: boutique_tcp_port_established_connections_total
      query: |
        sum(rate(boutique_tcp_port_established_connections_total{job =~ "recommendationservice"}[30s]))
      threshold: "3"
EOF

kubectl apply -f - <<EOF
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: currencyservice-scale
  namespace: "${PROJECT_NAMESPACE}"
spec:
  scaleTargetRef:
    kind: Deployment
    name: currencyservice
  minReplicaCount: 1
  maxReplicaCount: 20
  cooldownPeriod: 30
  pollingInterval: 1
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://${PROMHOST}:${PROMPORT}
      metricName: boutique_tcp_port_established_connections_total
      query: |
        sum(rate(boutique_tcp_port_established_connections_total{job =~ "currencyservice"}[30s]))
      threshold: "16"
EOF

kubectl apply -f - <<EOF
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: productcatalogservice-scale
  namespace: "${PROJECT_NAMESPACE}"
spec:
  scaleTargetRef:
    kind: Deployment
    name: productcatalogservice
  minReplicaCount: 1
  maxReplicaCount: 20
  cooldownPeriod: 30
  pollingInterval: 1
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://${PROMHOST}:${PROMPORT}
      metricName: boutique_tcp_port_established_connections_total
      query: |
        sum(rate(boutique_tcp_port_established_connections_total{job =~ "productcatalogservice"}[30s]))
      threshold: "5"
EOF

kubectl apply -f - <<EOF
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: cartservice-scale
  namespace: "${PROJECT_NAMESPACE}"
spec:
  scaleTargetRef:
    kind: Deployment
    name: cartservice
  minReplicaCount: 1
  maxReplicaCount: 20
  cooldownPeriod: 30
  pollingInterval: 1
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://${PROMHOST}:${PROMPORT}
      metricName: boutique_tcp_port_established_connections_total
      query: |
        sum(rate(boutique_tcp_port_established_connections_total{job =~ "cartservice"}[30s]))
      threshold: "3"
EOF

kubectl apply -f - <<EOF
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: frontend-scale
  namespace: "${PROJECT_NAMESPACE}"
spec:
  scaleTargetRef:
    kind: Deployment
    name: frontend
  minReplicaCount: 1
  maxReplicaCount: 5
  cooldownPeriod: 30
  pollingInterval: 1
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://${PROMHOST}:${PROMPORT}
      metricName: nginx_ingress_controller_request_duration_seconds_bucket
      query: |
        histogram_quantile(0.95, sum by (le)(rate(nginx_ingress_controller_request_duration_seconds_bucket{ingress =~ "frontend-ingress"}[10s])))
      threshold: "1"
EOF