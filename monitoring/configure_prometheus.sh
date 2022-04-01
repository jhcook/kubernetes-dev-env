#!/usr/bin/env bash
#
# Create services and a servicemonitor for Prometheus to capture metrics
#
# References:
# https://www.tigera.io/blog/how-to-monitor-calicos-ebpf-data-plane-for-proactive-cluster-management/
# https://rancher.com/docs/rancher/v2.6/en/monitoring-alerting/how-monitoring-works/
# https://support.coreos.com/hc/en-us/articles/360000155514-Prometheus-ServiceMonitor-troubleshooting
# https://rancher.com/docs/rancher/v2.6/en/monitoring-alerting/guides/customize-grafana/
#
# Author: Justin Cook


# Create services for Prometheus discovery
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: typha-metrics
  namespace: calico-system
  labels:
    k8s-app: calico-typha
spec:
  selector:
    k8s-app: calico-typha
  ports:
  - name: http-metrics
    port: 9093
    targetPort: 9093
EOF

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: calico-controllers-metrics
  namespace: calico-system
  labels:
    k8s-app: calico-kube-controllers
spec:
  selector:
    k8s-app: calico-kube-controllers
  ports:
  - name: http-metrics
    port: 9094
    targetPort: 9094
EOF

kubectl patch felixConfiguration default --patch \
  '{ "spec": { "prometheusMetricsEnabled": true } }' --type=merge

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: felix-metrics
  namespace: calico-system
  labels:
    k8s-app: calico-node
spec:
  selector:
    k8s-app: calico-node
  ports:
  - name: http-metrics
    port: 9091
    targetPort: 9091
EOF

kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: calico-typha-prometheus-config
  namespace: cattle-monitoring-system
spec:
  selector:
    matchLabels:
      k8s-app: calico-typha
  namespaceSelector:
    matchNames:
    - calico-system
  endpoints:
  - path: /metrics
    port: http-metrics
    interval: 10s
EOF

kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: calico-kube-controllers-prometheus-config
  namespace: cattle-monitoring-system
spec:
  selector:
    matchLabels:
      k8s-app: calico-kube-controllers
  namespaceSelector:
    matchNames:
    - calico-system
  endpoints:
  - path: /metrics
    port: http-metrics
    interval: 10s
EOF

kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: calico-svc-monitoring-prometheus-config
  namespace: cattle-monitoring-system
spec:
  selector:
    matchLabels:
      k8s-app: calico-node
  namespaceSelector:
    matchNames:
    - calico-system
  endpoints:
  - path: /metrics
    port: http-metrics
    interval: 10s
EOF