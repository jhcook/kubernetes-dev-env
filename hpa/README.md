# HPA

[Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

## Introduction

The Rancher 2.6.5 release has support for Kubernetes 1.23.x. As
such, it is the selected version in this build. Kubernetes 1.23 is used and
supports [`autoscaling/v2`](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/).

In the interest of backward compatibility, Keda is used with ScaledObject(s)
in the examples using the `sidecar` subdirectory.

## Prerequisites

A Docker registry running on $(minikube ip):${DOCKER_REG_PORT} and accessible
to localhost:${DOCKER_REG_PORT}. For more information, please see the `sidecar`
subdirectory.

## Installation

Execute `configure_hpa.sh` script in this directory. It will install Keda and
create a frontend at http://boutique.test.

Next, the sidecar and init containers need to be built and made available. The
[method will vary based on platform](https://minikube.sigs.k8s.io/docs/handbook/pushing/). For macOS, please use [the code in
this project](./sidecar/bootstrap.sh) to prepare and make available.
Finally, patch the relevant deployments to use the containers and create
ServiceMonitors for each.

```
$ bash hpa/sidecar/bootstrap.sh
...
$ bash hpa/sidecar/builder.sh
...
$ bash hpa/install_sidecar_init.sh
...
```

At this point, the pods are publishing metrics being scraped by Prometheus.
The last big is creating ScaledObjects Keda will use to modify workloads
accordingly.

```
$ bash hpa/install_scaled_objects.sh
...
```

create sidecar and an init container, modify the mock application (Boutique)
with Locust for load testing. Upon successful execution, it will print
instructions and make the Boutique available as `http://boutique.test`.

The Locust interface is made available as `http://0.0.0.0:8089.