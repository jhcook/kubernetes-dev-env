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
# Setup Minikube with Calico CNI, Rancher, install and configure monitoring,
# and install a boutique application for load testing.
#
# Author: Justin Cook

set -o errexit

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
