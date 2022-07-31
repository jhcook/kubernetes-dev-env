# sidecar

## Introduction
The code herein is used to create sidecar and init containers for various use
cases. 

The `bootstrap.sh` script is used to create a local Docker registry
for use with Minikube where these and other container images can be created
and managed locally. It requires `limactl` available with Minikube running.