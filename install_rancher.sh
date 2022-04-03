#!/usr/bin/env bash
#
# Install Rancher in a Kubernetes cluster
#
# Author: Justin Cook

set -o errexit

# shellcheck source=/dev/null
. env.sh

# Apply cert-manager crds
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.5.1/cert-manager.crds.yaml

# Add the appropriate Helm repos and update
helm repo add jetstack https://charts.jetstack.io
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update

# Install cert-manager
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.7.1

# Create the cattle-system namespace
kubectl create namespace cattle-system --dry-run=client -o yaml | \
  kubectl apply -f -

# Install Rancher
helm upgrade --install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.test \
  --set bootstrapPassword=admin \
  --version 2.6.4

# Wait for Rancher to become available
kubectl rollout status deploy/rancher -n cattle-system