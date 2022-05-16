# Kubernetes Development Environment

The Kubernetes Development Environment is a full-featured environment rendering
the full stack for a feature rich experience. 

By default, it uses Minikube, makes Rancher and Calico available, and provides
Prometheus monitoring and Grafana dashboards. The full stack is delivered as
code and is completely modular. 

It features a sidecar that provides TCP ESTABLISHED connections using
conntrack. This sidecar is featured in an example with Keda to scale objects
based on connection rate. 

The stack provides the latest Rancher release (2.6.4) and Calico with an option
for Calico Enterprise (3.13) -- for those with appropriate credentials.

## Up and Running

The following instructions have been wrapped and provided in `quickstart.sh`.
It was developed and tested on macOS using hyperkit. It requires Internet
connectivity, and requires just under ten minutes to complete on a 500Mbps
connection. Hyperkit uses 30GiB of RAM for the default configuration.

The code requires the following utilities to operate correctly. They are
available with `brew`.

* Minikube
* kubectl
* Helm
* Git
* Pip
* Virtualenv
* yq
* jq

```
bash quickstart.sh
...
Open browser to: http://10.109.73.206:30875

[2022-03-23 16:54:04,461] jcmmini1.local/INFO/locust.main: Starting web interface at http://0.0.0.0:8089 (accepting connections from all network interfaces)
[2022-03-23 16:54:04,475] jcmmini1.local/INFO/locust.main: Starting Locust 2.8.4
```

Please note, `quickstart.sh` does not enable eBPF or install Keda and configure
HPA with Prometheus metrics. It does, however, create a three node cluster;
install Calico, Rancher, and the monitoring stack; configure the relevant
Prometheus metrics and Grafana dashboards; and install Boutique.

## Demonstration of Calico CNI with eBPF the hard way 

Create a Minikube cluster enabling ingress and ingress-dns addon, set the
cidr range to 172.16.0.0/16, and set the Kubernetes version.
* https://www.suse.com/suse-rancher/support-matrix/all-supported-versions/rancher-v2-6-3/
* https://minikube.sigs.k8s.io/docs/drivers/hyperkit/

### Configure .test TLD to to use Minikube
* https://minikube.sigs.k8s.io/docs/handbook/addons/ingress-dns/

```
bash setup_k8s.sh
```

## Install Calico CNI
* https://projectcalico.docs.tigera.io/getting-started/kubernetes/minikube

```
bash install_calico.sh
```

## Add Nodes to Minikube

```
minikube config set memory 4096
minikube node add --worker
```
## Install Rancher
* https://rancher.com/docs/rancher/v2.6/en/installation/install-rancher-on-k8s/

```
bash install_rancher.sh
```

## Install / Configure Prometheus and Grafana 
* https://rancher.com/docs/rancher/v2.6/en/monitoring-alerting/guides/customize-grafana/
* https://rancher.com/docs/rancher/v2.6/en/monitoring-alerting/guides/persist-grafana/
* https://www.tigera.io/blog/monitoring-calico-with-prometheus-and-grafana/
* https://www.tigera.io/blog/how-to-monitor-calicos-ebpf-data-plane-for-proactive-cluster-management/
* https://projectcalico.docs.tigera.io/maintenance/monitor/monitor-component-metrics

```
bash install_monitoring.sh
```

Add the services necessary and create the Prometheus service monitors for
Calico.

```
bash monitoring/configure_prometheus.sh
...
bash monitoring/configure_grafana_dashboards.sh
...
```

## Enable Horizontal Pod Autoscaling
* https://www.nginx.com/blog/microservices-march-reduce-kubernetes-latency-with-autoscaling/

This can be done at any time and is simply a demonstration of using Keda to
scale workloads using Prometheus metrics. For more information, please see the
`hpa` directory.

```
bash hpa/configure_hpa.sh
```

The script above creates an ingress for http://boutique.test which becomes
available after the script runs successfully.

## Load Testing with Locust
* https://cloud.google.com/service-mesh/docs/onlineboutique-install-kpt
* https://github.com/GoogleCloudPlatform/microservices-demo

Create a virtual environment and install Locust. Then, clone the above repo,
install the application, setup Locust, and execute the load test.

```
bash install_boutique.sh
...
```

Open your browser and load the sites (Boutique and Locust) displayed.

## Enable eBPF
* https://projectcalico.docs.tigera.io/maintenance/ebpf/enabling-bpf

```
bash ebpf/enable_ebpf.sh
```

## Disable eBPF

```
bash ebpf/disable_ebpf.sh
```

## Calico Enterprise

For those with a valid Tigera Calico Enterprise license, please see the
`calico_enterprise` folder for more information. One caveat, it is recommended
to isnstall Rancher and monitoring before Calcio Enterprise if you prefer the
full stack to be available. This is due to the Prometheus operator and pull
secret visibility to the operator.
