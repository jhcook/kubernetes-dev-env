#!/usr/bin/env bash
#
# Create Grafana dashboards for additional services
#
# This exists as a wrapper for dashboards contained in files due to length.
#
# Author: Justin Cook

shopt -s nullglob

for dashboard in monitoring/dashboards/*.{yaml,json}
do
  printf "Applying Grafana dashboard: %s\n" "${dashboard}"
  kubectl apply -f "${dashboard}"
done