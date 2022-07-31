# HPA

[Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

## Introduction

The Rancher 2.6.5 release has support for Kubernetes 1.23.x. As
such, it is the selected version in this build. Kubernetes 1.23 is used and
supports [`autoscaling/v2`](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/).

In the interest of backward compatibility, Keda is used with ScaledObject(s)
in the examples using the `sidecar` subdirectory.

## Prerequisites

A local Docker registry running on localhost:5000 and accessible by Kubernetes.
For more information, please see the `sidecar` subdirectory.

## Installation

Execute `configure_hpa.sh` script in this directory. It will install Keda,
create sidecar and an init container, modify the mock application (Boutique)
with Locust for load testing. Upon successful execution, it will print
instructions and make the Boutique available as `http://boutique.test`.

The Locust interface is made available as `http://0.0.0.0:8089.