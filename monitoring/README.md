# Monitoring

This directory contains code to configure Prometheus and install Grafana
dashboards.

## Prometheus

`configure_prometheus.sh` creates services, patches deployments, and creates
ServiceMonitor(s) for NGINX and Calico. These metrics become available in
Prometheus as metrics. These metrics are useful for Grafana dashboards, HPA,
and Keda amongst others.

## Grafana

The `configure_grafana_dashboards.sh` is a simple convenience that iterates
through the `dashboards` directory installing `.json` or `.yaml` files which
are assumed to be Grafana dashboards.

The dashboards provided by default are NGINX and Calico. 