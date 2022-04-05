#!/usr/bin/env bash
#
# Setup Minikube with Calico CNI, Rancher, install and configure monitoring,
# and install a boutique application for load testing.
#
# Author: Justin Cook

# shellcheck source=/dev/null
. env.sh

trap "exit" INT

# Configure Minikube
bash setup_k8s.sh

# Install Calico
bash install_calico.sh

# Install Rancher
bash install_rancher.sh

# Install and configure Prometheus metrics / Grafana dashboards
bash install_monitoring.sh
bash monitoring/configure_prometheus.sh
bash monitoring/configure_grafana_dashboards.sh

# Install boutique
bash install_boutique.sh
