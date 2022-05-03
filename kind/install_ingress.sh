#!/usr/bin/env bash
#
# Create an NGINX Ingress
# Reference: https://kind.sigs.k8s.io/docs/user/ingress/
#
# Author: Justin Cook

# Create NGINX Ingress controller with complete rbac
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Patch the nginx-deployment to only run on ingress-ready=true labelled hosts
kubectl patch deployments ingress-nginx-controller -n ingress-nginx -p \
  '{"spec": {"template": {"spec": {"nodeSelector": {"ingress-ready": "true"}}}}}'

# Wait for the controller to start
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
