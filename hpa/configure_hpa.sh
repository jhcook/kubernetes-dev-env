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
#
# Author: Justin Cook

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
kubectl apply -f hpa/frontend-ingress.yaml

# Patch each deployment with custom exporter to make metrics available via
# Prometheus. Patch the cooresponding service to include said endpoint
# then follow up by creating a ServiceMonitor. Give yourself a pat on the back,
# Prometheus is now collecting metrics from your clever exporter.
for deploy in $(kubectl get deploy -n default -o name)
do
  SVCPORT="$(kubectl get svc ${deploy#*/} -n default -o \
             jsonpath='{.spec.ports[-1].port}' 2>/dev/null)" || continue
  
  printf "Patching service %s with TCP %s\n" "${deploy#*/}" "${SVCPORT}"
  kubectl patch svc "${deploy#*/}" -n default \
  -p='{"spec": {"type": "ClusterIP","ports": [{"name": "prometheus","port": 9100,"protocol": "TCP","targetPort": 9100}]}}'

  kubectl patch svc "${deploy#*/}" -n default \
  -p="{\"metadata\": {\"labels\": {\"k8s-app\": \"${deploy#*/}\"}}}"

  printf "Patching %s\n" "${deploy}"
  # kubectl patch --patch-file does not accept here docs :-/
  cat << EOF >/tmp/$$.tmp
spec:
  template:
    spec:
      containers:
      - name: tcp-exporter
        image: localhost:5000/jhcook/tcp-exporter:latest
        imagePullPolicy: IfNotPresent
        securityContext:
          capabilities:
            add: ["NET_ADMIN"]
        args: ["9100", "${SVCPORT}"]
        ports:
          - containerPort: 9100
            protocol: TCP
EOF
  kubectl patch "${deploy}" -n default --patch-file /tmp/$$.tmp
  rm -f /tmp/$$.tmp

  kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: boutique-${deploy#*/}-prometheus-config
  namespace: cattle-monitoring-system
spec:
  selector:
    matchLabels:
      k8s-app: "${deploy#*/}"
  namespaceSelector:
    matchNames:
    - default
  endpoints:
  - path: /metrics
    port: prometheus
    interval: 10s
EOF
done

# Create the ScaledObject(s)
PROMHOST=$(kubectl get svc rancher-monitoring-prometheus -n \
           cattle-monitoring-system -o jsonpath='{.spec.clusterIP}')

kubectl apply -f - <<EOF
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: recommendationservice-scale
  namespace: default
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
      serverAddress: http://${PROMHOST}:9090
      metricName: nginx_ingress_controller_requests
      query: |
        sum(rate(nginx_ingress_controller_requests[30s]))
      threshold: "30"
EOF

kubectl apply -f - <<EOF
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: currencyservice-scale
  namespace: default
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
      serverAddress: http://${PROMHOST}:9090
      metricName: nginx_ingress_controller_requests
      query: |
        sum(rate(nginx_ingress_controller_requests[30s]))
      threshold: "60"
EOF

kubectl apply -f - <<EOF
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: productcatalogservice-scale
  namespace: default
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
      serverAddress: http://${PROMHOST}:9090
      metricName: nginx_ingress_controller_requests
      query: |
        sum(rate(nginx_ingress_controller_requests[30s]))
      threshold: "60"
EOF

kubectl apply -f - <<EOF
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: cartservice-scale
  namespace: default
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
      serverAddress: http://${PROMHOST}:9090
      metricName: nginx_ingress_controller_requests
      query: |
        sum(rate(nginx_ingress_controller_requests[30s]))
      threshold: "30"
EOF

kubectl apply -f - <<EOF
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: frontend-scale
  namespace: default
spec:
  scaleTargetRef:
    kind: Deployment
    name: frontend
  minReplicaCount: 1
  maxReplicaCount: 20
  cooldownPeriod: 30
  pollingInterval: 1
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://${PROMHOST}:9090
      metricName: nginx_ingress_controller_request_duration_seconds_bucket
      query: |
        histogram_quantile(0.95, sum by (le)(rate(nginx_ingress_controller_request_duration_seconds_bucket{ingress =~ "frontend-ingress"}[10s])))
      threshold: "1"
EOF