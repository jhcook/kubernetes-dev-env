#!/usr/bin/env bash
#
# Install Online Boutique for Kubernetes sample and load testing
#
# Author: Justin Cook

set -o errexit

# Check if the virtualenv exists. If not, create it.
if [ ! -d "venv" ]
then
  virtualenv venv
fi

# Activate the virtualenv and install locust
source ./venv/bin/activate
pip install locust

# Check if the boutique, aka microservices-demo, exists. If not, clone it.
if [ ! -d "microservices-demo" ]
then
  git clone https://github.com/GoogleCloudPlatform/microservices-demo.git
fi

# Install the boutique.
cd microservices-demo || exit
kubectl apply -f ./release/kubernetes-manifests.yaml

# Wait for the boutique to become available.
for deploy in $(kubectl get deploy -n default -o name)
do 
  kubectl rollout status "${deploy}"
done

# Get the IP:Port and display to the user
#BOUTIQUE=$(kubectl get service frontend-external -o \
#           jsonpath='{.spec.clusterIP}{":"}{.spec.ports[*].nodePort}{"\n"}')

BOUTIQUE="$(minikube ip -p calico):$(kubectl get service frontend-external -o \
            jsonpath='{.spec.ports[*].nodePort}{"\n"}')"

printf "\n\nOpen browser to: "
printf "http://%s\n\n" "${BOUTIQUE}"

# Run locust
cd src/loadgenerator || exit
locust