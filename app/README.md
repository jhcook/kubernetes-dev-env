# Boutique

This is Google's [Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo) which is a cloud-first microservices demo
application.Online Boutique consists of an 11-tier microservices application.
The application is a web-based e-commerce app where users can browse items, add
them to the cart, and purchase them.

Google uses this application to demonstrate use of technologies like
Kubernetes/GKE, Istio, Stackdriver, and gRPC. This application works on any
Kubernetes cluster, as well as Google Kubernetes Engine. It’s easy to deploy
with little to no configuration.

## Introduction

The Online Boutique is made availabe here to demonstrate and make Locust
availabile for load testing. 

## Getting Started

With KUBECONFIG correctly set and a context using the specific cluster and
namespace, you can install the demo with `bash app/install_boutique.sh`.

Given the Kubenetes platform, ingress may be automatically configured. In case
it is not, apply the ingress located in `hpa` directory in this repo.

```
$ kubectl apply -f hpa/frontend-ingress.yaml
ingress.networking.k8s.io/frontend-ingress created
```

The demo is available on http://boutique.test if resolution is configured.