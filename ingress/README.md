# Ingress

An API object that manages external access to the services in a cluster,
typically HTTP.

## Introduction

Ingress exposes HTTP and HTTPS routes from outside the cluster to services
within the cluster. Traffic routing is controlled by rules defined on the
Ingress resource.

You must have an Ingress controller to satisfy an Ingress. Only creating an
Ingress resource has no effect.

You may need to deploy an Ingress controller such as ingress-nginx. You can
choose from a number of Ingress controllers.

## Getting Started

If you are using `setup_k8s.sh` provided with Minikube, NGINX ingress is
installed and configured for you. Other configurations for other providers are
provided as necessary.

## NGINX

ingress-nginx can be used for many use cases, inside various cloud providers,
and supports a lot of configurations. `install_nginx_ingress.sh` in this
directory installs the operator using Helm for supported platforms.

## References

* [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
* [Kubernetes Ingress Controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)
* [NGINX Ingress](https://kubernetes.github.io/ingress-nginx/deploy/)
*[Set up Ingress on Minikube with the NGINX Ingress Controller](https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/)
