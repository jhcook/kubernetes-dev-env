# Rancher

## Introduction

Rancher is known early on in the Kubernetes ecosystem from Rancher Manager
which deploys and manages multi-cluster apps. It unifies several other
Kubernetes resources such as Prometheus and Grafana.

The code in this directory focuses on deploying and configuring Rancher Manager
for use with applications. Rancher Desktop can be used as a Kubernetes cluster
provider. We will make efforts to distinguish Rancher Desktop when applicable.
But, please assume the use of Rancher refers to Rancher Manager unless stated
otherwise.

## Rancher Desktop

While Rancher and Rancher Desktop share the Rancher name they do different things. Rancher Desktop is not Rancher on the Desktop. Rancher is a powerful solution to manage Kubernetes clusters. Rancher Desktop provides a local Kubernetes and container management platform. The two solutions complement each other. If you want to run Rancher on your local system, you can install Rancher into Rancher Desktop.

## Getting Started

Installing Rancher requires a running Kubernetes cluster with adequate
resources and no colliding installed resources. This can be achieved by running
`install_rancher.sh` provided in this directory.

## Resources
* [Why Rancher](https://www.rancher.com/why-rancher)
* [Rancher Desktop](https://docs.rancherdesktop.io/)