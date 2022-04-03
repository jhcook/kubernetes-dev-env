#!/usr/bin/env bash
#
# Configures an existing Kubernetes cluster with Calico CNI to use eBPF
# https://projectcalico.docs.tigera.io/maintenance/ebpf/enabling-bpf
#
# Author: Justin Cook

set -x

# shellcheck source=/dev/null
. env.sh

IFS=':' read -ra ENDPNT <<< "$(kubectl get endpoints kubernetes | awk '/^kubernetes/{print$2}')"

cat <<EOF | kubectl apply -f -
kind: ConfigMap
apiVersion: v1
metadata:
  name: kubernetes-services-endpoint
  namespace: tigera-operator
data:
  KUBERNETES_SERVICE_HOST: "${ENDPNT[0]}"
  KUBERNETES_SERVICE_PORT: "${ENDPNT[1]}"
EOF

# Wait for kubelet to pick up changes
sleep 60

# Delete the operator to pick up the change
kubectl delete pod -n tigera-operator -l k8s-app=tigera-operator

# Wait on pods to restart
kubectl rollout status ds/calico-node -n calico-system

# Disable kube-proxy
kubectl patch ds -n kube-system kube-proxy -p '{"spec":{"template":{"spec":{"nodeSelector":{"non-calico": "true"}}}}}'

# Enable eBPF
kubectl patch installation.operator.tigera.io default --type merge -p '{"spec":{"calicoNetwork":{"linuxDataplane":"BPF", "hostPorts":null}}}'
