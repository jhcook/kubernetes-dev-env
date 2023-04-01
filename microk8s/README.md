# MicroK8s

## Introduction
A lightweight Kubernetes distro that claims zero-ops, and pure-upstream Kubernetes, 
from developer workstations to production.

https://microk8s.io

## Quickstart
To get up and running, ensure `microk8s` is installed with `multipass` and
`jq`. If those applications are in your PATH, then execute the following
script. The script is idempotent and can be ran to create and join nodes:

```
$ bash microk8s/setup_microk8s.sh
...
```

The cluster can be destroyed with `bash microk8s/remove_microk8s.sh`.

## Getting Started
On macOS:

```
$ brew install ubuntu/microk8s/microk8s
==> Tapping ubuntu/microk8s
Cloning into '/usr/local/Homebrew/Library/Taps/ubuntu/homebrew-microk8s'...
...
```

Once installed, you may enable Kubernetes by simply executing the following:

```
$ microk8s install
warning: "--mem" long option will be deprecated in favour of "--memory" in a future release.Please update any scripts, etc.
Launched: microk8s-vm                                                           
2023-03-30T11:48:22+11:00 INFO Waiting for automatic snapd restart...
microk8s (1.26/stable) v1.26.1 from Canonical✓ installed
microk8s-integrator-macos 0.1 from Canonical✓ installed
MicroK8s is up and running. See the available commands with `microk8s --help`.
```

Wait for Kubernetes to become ready.

```
$ microk8s status --wait-ready
```

Install the required services to support the development environment:

```
$ microk8s enable ingress dns registry
Infer repository core for addon ingress
Infer repository core for addon dns
Infer repository core for addon registry
...
```

## Kubernetes Version

In order to install a specific version of Kubernetes on `microk8s`, you will
need to configure snap on the virtual machine that has been created with
install.

```
$ multipass shell microk8s-vm
...
ubuntu@microk8s-vm:~$ sudo snap refresh microk8s --classic --channel=1.24/stable
microk8s (1.24/stable) v1.24.12 from Canonical✓ refreshed
ubuntu@microk8s-vm:~$ logout
$ microk8s stop
Stopped.
$ microk8s start
Started.
```

More information can be found on [snap channels here](ttps://microk8s.io/docs/setting-snap-channel).

## Troubleshooting

If you have previously used `multipass`, you may find your previous
configuration is incompatible with `microk8s`. In this situation, you need to
refer to the relevant documentation for your platform. 

https://multipass.run/docs

In some cases, you may have used a driver that is not default for the platform.
This can be changed as an example for macOS:

```
$ multipass autheticate
...
$ sudo -E multipass set local.driver=hyperkit
```