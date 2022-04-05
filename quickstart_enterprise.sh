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
sh setup_k8s.sh

# Install Rancher
sh install_rancher.sh

# Install Prometheus
sh install_monitoring.sh

# Install Calico
sh calico_enterprise/install_calico_enterprise.sh

# Configure Prometheus metrics / Grafana dashboards
#sh monitoring/configure_prometheus.sh
#sh monitoring/configure_grafana_dashboards.sh

# Install boutique
#sh install_boutique.sh
