# Kubernetes Development Environment Docs

Welcome to this project's documentation. 

Here you can access the complete documentation for this rich development
toolset. 

## Introduction

The overall goal of this development environment is providing a full stack for
the easy integration of Kubernetes into an ecosystem, developing applications
with complete integration to Kubernetes, integrating major components into a
Kubernetes deployment, and perfecting infrastructure as code. After all, every
component herein is provisioned, installed, and configured as code.

## Installation

Installation of this repository and dependencies can be found in
[install documentation](./install/index.md).

## Major Components

Each major component is made available in the root directory as an install
script. For instance, `./install_calico.sh` installs the Calico CNI. Each
subdirectory may contain experimental code, a specific collection of code,
or an entire project that integrates with the full stack. 

A list of components this project makes available and support are:
* [Minikube](https://minikube.sigs.k8s.io/docs/)
* [OpenShift Local](https://developers.redhat.com/products/openshift-local/overview)
* [Calico CNI](https://github.com/projectcalico/calico)
* [Rancher](https://rancher.com)
* [Prometheus](https://github.com/prometheus-operator/prometheus-operator)
* [Grafana](https://github.com/grafana-operator/grafana-operator)
* Google's [Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo)

Projects for displaying use cases and assisting with integration are:
* [Monitoring](../monitoring/README.md)
* [Horizontal pod autoscaling](../hpa/README.md)
* [eBPF](../ebpf/README.md)
* [Calico Enterprise](../calico_enterprise/README.md)

## Integration

Information on integration with upstream components can be found in
[integration](./integration/index.md).

## Tutorials

Several use case tutorials can be found in [tutorials](./tutorials/index.md).

## Contributing

Contributions are welcome. We ask everyone to follow the [code of conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/code_of_conduct.md)
or you will be asked not or disallowed to participate.

Contributing code is encouraged. We ask when submitting a pull request, that it
contain complete documentation and be submitted to this repository's `devel`
branch.

Also, we encourage all integrations or use case implementations take advantage
of Kubernetes capabilities such as monitoring, autoscaling, and observability.
For each of these capabilities, please use any of this project's existing code.
