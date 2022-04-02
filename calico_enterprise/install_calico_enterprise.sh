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
#
# Author: Justin Cook

_NS_="tigera-operator"

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

for secret in $(kubectl get secrets -n "${_NS_}" -o name)
do
  if [ "${secret#*/}" == "tigera-pull-secret" ]
  then
    kubectl delete secret tigera-pull-secret -n "${_NS_}"
    break
  fi
done

kubectl create secret generic tigera-pull-secret \
    --type=kubernetes.io/dockerconfigjson -n "${_NS_}" \
    --from-file=.dockerconfigjson=calico_enterprise/tigera-pull-secret.json

# Install Tigera custom resources
kubectl apply -f https://docs.tigera.io/manifests/custom-resources.yaml

# Wait until apiserver is Available
printf "Waiting on APIServer: "
while :
do
  status="$(kubectl get tigerastatus apiserver --no-headers 2>&1 | awk '{print$2}')"
  if [ "${status}" == "True" ]
  then
    printf "Available\n"
    break
  fi
  sleep 2
done

# Wait on calico to become Available
printf "Waiting on Calico: "
while :
do
  status="$(kubectl get tigerastatus calico --no-headers 2>&1 | awk '{print$2}')"
  if [ "${status}" == "True" ]
  then
    printf "Available\n"
    break
  fi
  sleep 2
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
