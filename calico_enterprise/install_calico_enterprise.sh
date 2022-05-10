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
#  * https://docs.tigera.io/getting-started/cnx/authentication-quickstart
#  * https://minikube.sigs.k8s.io/docs/handbook/persistent_volumes/
#
# Tested on:
#  * macOS Montery 
#
# Author: Justin Cook

set -o errexit
set -o nounset
set -o pipefail

# shellcheck source=/dev/null
. env.sh

_NS_="tigera-operator"

# Remove master taint
kubectl taint nodes --all node-role.kubernetes.io/master- || /usr/bin/true

# Create a persistent volume for ElasticSearch
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0001
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 50Gi
  storageClassName: tigera-elasticsearch
  hostPath:
    path: /data/pv0001/
EOF

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

# Create a pull secret for the Tigera Prometheus operator and patch deployment.
# In order to be idempotent, we need to be pedantic checking promtheuses and
# known namespaces as prometheus API not available will change at a later date
# and assumptions will become invalid.
if ! kubectl get prometheus >/dev/null 2>&1
then
  PROMOPNS="tigera-prometheus"
  PROMOPDP="calico-prometheus-operator"
  kubectl apply -f https://docs.tigera.io/manifests/tigera-prometheus-operator.yaml
else
  if kubectl get ns cattle-monitoring-system >/dev/null 2>&1
  then
    PROMOPNS="cattle-monitoring-system"
    PROMOPDP="rancher-monitoring-operator"
  else
    PROMOPNS="tigera-prometheus"
    PROMOPDP="calico-prometheus-operator"
  fi
  kubectl create ns tigera-prometheus --dry-run=client -o yaml | \
    kubectl apply -f -
fi

kubectl create secret generic tigera-pull-secret \
  --type=kubernetes.io/dockerconfigjson -n ${PROMOPNS} \
  --from-file=.dockerconfigjson=calico_enterprise/tigera-pull-secret.json \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl patch deployment -n ${PROMOPNS} ${PROMOPDP} \
  -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name": "tigera-pull-secret"}]}}}}'

# Install Tigera custom resources
kubectl apply -f https://docs.tigera.io/manifests/custom-resources.yaml

# Helper function to verify tigerastatus is available. In order to circumvent
# flapping, get three consecutive success to proceed.
tigerastatus() {
  # Wait for tigerastatuses.operator.tigera.io API group and kind
  while :
  do
    kubectl get tigerastatus "$1" >/dev/null 2>&1 && break
    sleep 2
  done
  success_count=0
  until [ "$success_count" -gt 2 ]
  do
    status=$(kubectl get tigerastatus "$1" --no-headers)
    avail=$(echo "${status:${#1}+3:5}" | xargs)
    if [ "${avail:-False}" == "True" ]
    then
      ((success_count++))
    else
      success_count=0
    fi
    sleep 2
  done
}

# Wait until apiserver and calico are Available. 
for serv in calico apiserver
do
  printf "Waiting on %s: " "${serv}"
  tigerastatus "${serv}"
  printf "Available\n"
done

# Install the Calico Enterprise license
kubectl apply -f calico_enterprise/calico-enterprise-license.yaml

# Wait for all components to become available
printf "Waiting on all components: "

for serv in monitor log-storage compliance intrusion-detection log-collector manager
do
  tigerastatus "${serv}"
done

printf "Available\n"

# Secure Calico Enterprise components with network policy
kubectl apply -f https://docs.tigera.io/manifests/tigera-policies.yaml

# Create an admin user
kubectl create sa admin -n default --dry-run=client -o yaml | kubectl apply -f -
kubectl create clusterrolebinding admin-access --clusterrole tigera-network-admin\
  --serviceaccount default:admin --dry-run=client -o yaml | kubectl apply -f -

# Output elastic and admin user's token
printf "\nKibana \"elastic\" user token: "
kubectl -n tigera-elasticsearch get secret tigera-secure-es-elastic-user \
  -o go-template='{{.data.elastic | base64decode}}' && echo

printf "\nCalico \"admin\" user token: "
kubectl get secret "$(kubectl get serviceaccount admin -o jsonpath='{range .secrets[*]}{.name}{"\n"}{end}' | grep token)" \
  -o go-template='{{.data.token | base64decode}}' && echo

printf "\nVisit https://localhost:9443/ to login to the Calico Enterprise UI with token above.\n\n"

kubectl port-forward -n tigera-manager svc/tigera-manager 9443
