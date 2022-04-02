#!/usr/bin/env bash
#
# Install Calico Enterprise
#
# Prerequisites: 
#  * Tiger operator and custom resource definitions installed
#  * Prometheus operator installed
#  * Pull secret `tigera-pull-secret.json` in this folder
#  * Calico Enterprise license `calico-enterprise-license.yaml` in this folder
#  
# References:
#  * https://docs.tigera.io/getting-started/kubernetes/rancher
#  * https://docs.tigera.io/maintenance/monitor/support
#
# Author: Justin Cook

_NS_="tigera-operator"

# Remove master taint
kubectl taint nodes --all node-role.kubernetes.io/master-

# Create persistent volumes
for i in {1..5}
do
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv000${i}
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 50Gi
  storageClassName: tigera-elasticsearch
  hostPath:
    path: /data/pv000${i}/
EOF
done

# Create a StorageClass
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: tigera-elasticsearch
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Retain
EOF

# Install the Tigera operator and custom resource definitions
kubectl apply -f https://docs.tigera.io/manifests/tigera-operator.yaml

# Check if existing APIServer in tigera-operator namespace
kubectl get APIServer default -n "${_NS_}" >/dev/null 2>&1 && \
kubectl delete APIServer default -n "${_NS_}"

# Install the pull secret
kubectl create secret generic tigera-pull-secret \
    --type=kubernetes.io/dockerconfigjson -n "${_NS_}" \
    --from-file=.dockerconfigjson=calico_enterprise/tigera-pull-secret.json \
    --dry-run=client -o yaml | kubectl apply -f -

# Create a pull secret for the Tigera Prometheus operator and patch deployment
#kubectl create namespace tigera-prometheus --dry-run=client -o yaml | \
#  kubectl apply -f -
kubectl apply -f https://docs.tigera.io/manifests/tigera-prometheus-operator.yaml
kubectl create secret generic tigera-pull-secret \
    --type=kubernetes.io/dockerconfigjson -n tigera-prometheus \
    --from-file=.dockerconfigjson=calico_enterprise/tigera-pull-secret.json \
    --dry-run=client -o yaml | kubectl apply -f -
kubectl patch deployment -n tigera-prometheus calico-prometheus-operator \
    -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name": "tigera-pull-secret"}]}}}}'

# Install Tigera custom resources
kubectl apply -f https://docs.tigera.io/manifests/custom-resources.yaml

# Wait until apiserver and calico are Available. In order to circumvent
# flapping, get three consecutive success to proceed.
for serv in apiserver calico
do
  printf "Waiting on %s: " "${serv}"
  success_count=0
  while :
  do
    status="$(kubectl get tigerastatus ${serv} --no-headers 2>&1 | awk '{print$2}')"
    if [ "${status}" == "True" ]
    then
      ((success_count++))
      if [ "$success_count" -gt 2 ]
      then
        printf "Available\n"
        break
      fi
    else
      success_count=0
    fi
    sleep 2
  done
done

# Install the Calico Enterprise license
kubectl apply -f calico_enterprise/calico-enterprise-license.yaml

# Wait for all components to become available
printf "Waiting on all components: "
AVAIL=False
until ${AVAIL}
do
  for condition in $(kubectl get tigerastatus --no-headers | sort -rk2 | awk '{print$2}')
  do
    if [ "${condition}" != "True" ]
    then
      sleep 2
      AVAIL=False
      break
    else
      AVAIL=True
    fi
  done
done

printf "Available\n"

# Secure Calico Enterprise components with network policy
kubectl apply -f https://docs.tigera.io/manifests/tigera-policies.yaml

# Create an admin user
kubectl create sa admin -n default
kubectl create clusterrolebinding admin-access --clusterrole tigera-network-admin --serviceaccount default:admin
kubectl get secret "$(kubectl get serviceaccount admin -o jsonpath='{range .secrets[*]}{.name}{"\n"}{end}' | grep token)" -o go-template='{{.data.token | base64decode}}' && echo

kubectl port-forward -n tigera-manager svc/tigera-manager 9443

printf "Visit https://localhost:9443/ to login to the Calico Enterprise UI with token above.\n\n"
