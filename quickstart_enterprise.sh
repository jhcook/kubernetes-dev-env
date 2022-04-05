#!/usr/bin/env bash
#
# Setup Minikube with Rancher and install monitoring and Calico Enterprise.
# Afterward, configuring Prometheus and Grafana and installing Boutique neeed
# completed separately as they exit with runtime.
#
# Author: Justin Cook

# shellcheck source=/dev/null
. env.sh

trap "exit" INT

# Configure Minikube
bash setup_k8s.sh

# Install Rancher
bash install_rancher.sh

# Install Prometheus
bash install_monitoring.sh

# Install Calico
bash calico_enterprise/install_calico_enterprise.sh

# Configure Prometheus metrics / Grafana dashboards
#bash monitoring/configure_prometheus.sh
#bash monitoring/configure_grafana_dashboards.sh

# Install boutique
#bash install_boutique.sh
