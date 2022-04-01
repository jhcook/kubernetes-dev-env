#!/usr/bin/env bash
#
# Setup Minikube with Calico CNI, Rancher, install and configure monitoring,
# and install a boutique application for load testing.
#
# Author: Justin Cook

trap "exit" INT

# Configure Minikube
sh setup_k8s.sh

# Install Calico
sh install_calico.sh

# Install Rancher
sh install_rancher.sh

# Install and configure monitoring
sh install_monitoring.sh
sh monitoring/configure_prometheus.sh
kubectl apply -f monitoring/calico-grafana-dashboards.yaml

# Install boutique
sh install_boutique.sh
