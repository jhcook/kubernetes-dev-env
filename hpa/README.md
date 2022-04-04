# HPA

[Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

## Introduction

The Rancher 2.6.4 release has experimental support for Kubernetes 1.23.4. As
such, it is the selected version in this build. Kubernetes 1.23.4 is used primarly because it supports [`autoscaling/v2`](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/).

Keda is used with ScaledObject(s) in the examples using the `sidecar` available
in the root of this repository.

## Installation

Execute `configure_hap.sh` script in this directory. It will install Keda and
a mock application (Boutique) with Locust for load testing. Upon successful
execution, it will print instructions and make the Boutique available as
`http://boutique.test`.

The Locust interface is made available as `http://0.0.0.0:8089.