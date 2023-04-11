# Kubernetes Development Environment Installation

Installing this product requires one to have `git` installed. There are several
methods of doing so:
* [Git SCM](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
* [Git SCM Downloads](https://git-scm.com/downloads)
* [Atlassian](https://www.atlassian.com/git/tutorials/install-git)
* [GitLab](https://docs.gitlab.com/ee/topics/git/how_to_install_git/)
* [GitHub](https://github.com/git-guides/install-git)

## Install

Installing the project is can be achieved either downloading or cloning the Git
repository which can be found on [GitHub](https://github.com/jhcook/kubernetes-dev-env).

```
$ git clone https://github.com/jhcook/kubernetes-dev-env.git
```

or

```
$ gh repo clone jhcook/kubernetes-dev-env
```

## Dependencies

This project requires access to a Kubernetes cluster. This code supports
instantiating:
* [Minikube](https://minikube.sigs.k8s.io/docs/start/)
* [Kind](https://kind.sigs.k8s.io)
* [OpenShift Local](https://console.redhat.com/openshift/create/local)
* [Rancher Desktop](https://rancherdesktop.io)
* [Microk8s](https://microk8s.io)

## Configuration

Configuring the code is done via the `env.sh` file in the root folder. A
description of each configuration item can be found in [configuration](./operations/configuration.md).

Due to limitations with scope of and use of aliases in Bash code, platform-
specific generic aliases and environment data are kept in `platform.sh`.

Setting 