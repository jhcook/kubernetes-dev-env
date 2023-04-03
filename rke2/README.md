# Multipass RKE2

## Introduction

Get an instant Ubuntu VM with a single command. Multipass can launch and run
virtual machines and configure them with cloud-init like a public cloud.

https://multipass.run

RKE2, also known as RKE Government, is Rancher's next-generation Kubernetes
distribution.

It is a fully conformant Kubernetes distribution that focuses on security and
compliance within the U.S. Federal Government sector.

https://docs.rke2.io

## Getting Started

```
$ bash rke2/setup_rke2.sh
...
```

## Clean Up

When finished, you may delete all nodes, for example:

```
$ bash rke2/remove_rke2.sh
...
```
