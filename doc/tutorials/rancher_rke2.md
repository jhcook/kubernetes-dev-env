# Rancher on RKE2

Rancher is an open source container management platform built for organizations that deploy containers in production. Rancher makes it easy to run Kubernetes everywhere, meet IT requirements, and empower DevOps teams.

RKE2 is the next iteration of the Rancher Kubernetes Engine for datacenter use cases. The distribution runs standalone and integration work into Rancher is underway.

## Introduction

In the [rke2 directory](../../rke2/README.md) in this repo, configuration and code is available to
deploy a Canonical Multipass cluster on a workstation.

## Prerequisites

* Multipass
* jq

On macOS, these may be [installed](https://multipass.run/docs/installing-on-macos) by executing Homebrew:

```
$ brew install --cask multipass
...
$ brew install jq
...
```
[Windows](https://multipass.run/docs/installing-on-windows) and [Linux](https://multipass.run/docs/installing-on-linux) instructions are available.

## Configuration

The [configuration](../../rke2/localenv.sh) of RKE2 on Multipass resides alongside the code in the
directory above. Each configuration item is self explanatory. However, NAME and
TOKEN may be left blank, or "". In this case, one will be randomly created, and
the convenience scripts will self update and work transparently. Adding masters
and nodes is supported as long as TOKEN and NAME remain the same value.

In [`env.sh`](../../env.sh), set RUNTIME to rke2.

```
export RUNTIME="rke2"
```

## Installation

### RKE2

With prerequisite software installed and configuration either customised or
pristine, simply execute the setup_rke2.sh code provided.

```
$ bash rke2/setup_rke2.sh 
...
Context "generic-rke2-cluster" created.
rke2 setup complete
NAME                    STATUS   ROLES                       AGE     VERSION
generic-rke2-agent-1    Ready    <none>                      3m34s   v1.24.12+rke2r1
generic-rke2-agent-2    Ready    <none>                      64s     v1.24.12+rke2r1
generic-rke2-master-1   Ready    control-plane,etcd,master   5m44s   v1.24.12+rke2r1
Please configure rancher.test to resolve to 192.168.205.2
```

If `kubectl` is available in your PATH, a context will be created and be set as
default. Otherwise, information will ge provided to alias the master instance's
binary. For instance:

```
$ kubectl get ns
NAME              STATUS   AGE
default           Active   7m17s
kube-node-lease   Active   7m19s
kube-public       Active   7m19s
kube-system       Active   7m19s
```

Please note, the end of the output asks to configure resolution for
rancher.test, or the custom TLSSAN to the IP address that matches your
platform.

```
$ grep rancher.test /etc/hosts
192.168.205.2 rancher.test
```

### Rancher

Installation of Rancher is provided by executing the [`install_rancher.sh`](../../rancher/install_rancher.sh)
script.

```
$ bash rancher/install_rancher.sh 
...
Happy Containering!
Waiting for deployment "rancher" rollout to finish: 0 out of 3 new replicas have been updated...
Waiting for deployment "rancher" rollout to finish: 0 out of 3 new replicas have been updated...
Waiting for deployment "rancher" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment spec update to be observed...
Waiting for deployment "rancher" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "rancher" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "rancher" rollout to finish: 2 of 3 updated replicas are available...
deployment "rancher" successfully rolled out
```

Upon completion, if you configured resolution to TLSSAN -- defaults to
rancher.test -- in the configuration, you can open your browser to
http://rancher.test and login with the bootstrap password: admin

### Monitoring

Rancher provides Cluster Tools options that includes Monitoring. The
rancher-monitor operator is powered by Promtheus, Grafana, Alertmanager, the
Prometheus Operator, and the Prometheus adapter.

The monitoring application:

* Monitors the state and processes of your cluster nodes, Kubernetes
components, and software deployments.
* Defines alerts based on metrics collected via Prometheus.
* Creates custom Grafana dashboards.
* Configures alert-based notifications via email, Slack, PagerDuty, etc. using
Prometheus Alertmanager.
* Defines precomputed, frequently needed or computationally expensive
expressions as new time series based on metrics collected via Prometheus.
* Exposes collected metrics from Prometheus to the Kubernetes Custom Metrics API via Prometheus Adapter for use in HPA.

See a [detailed explanation](https://ranchermanager.docs.rancher.com/integrations-in-rancher/monitoring-and-alerting/how-monitoring-works) of how the monitoring components work together.

`rancher-monitoring` can be installed with the provided [install_monitoring.sh](../../rancher/install_monitoring.sh).

```
$ bash rancher/install_monitoring.sh 
...
Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.
deployment "rancher-monitoring-grafana" successfully rolled out
deployment "rancher-monitoring-kube-state-metrics" successfully rolled out
deployment "rancher-monitoring-operator" successfully rolled out
deployment "rancher-monitoring-prometheus-adapter" successfully rolled out
```

### Online Boutique

You're now in possession of a fully-featured Kubernetes cluster managed by
Rancher and monitored by Prometheus et al. This is great, but now let's deploy
a web application we can view in our browser. 

In order to install the lastest version of Google's Online Boutique, please
execute the code as shown below. And note, depending on your platform, you
may be prompted to allow incoming connections. The code uses Python's
virtualenv, downloads several dependencies, clones Google's microservices-demo,
applies Kubernetes objects, and ends listening on 0.0.0.0:8089.

```
$ bash app/install_boutique.sh
...
Please configure name resolution boutique.test to master's IP.

Open browser to: http://boutique.test

[2023-04-11 11:31:51,396] jcmmini1.local/INFO/locust.main: Starting web interface at http://0.0.0.0:8089 (accepting connections from all network interfaces)
[2023-04-11 11:31:51,410] jcmmini1.local/INFO/locust.main: Starting Locust 2.15.1
```

According to the instructions, you will need to ensure boutique.test resolves
to the IP address that in this case is the same that was revealed when RKE2 was
installed earlier.

```
$ grep boutique.test /etc/hosts
192.168.205.2 boutique.test
```

### Locust

As displayed by the instructions above, you can open your browser to
http://boutique.test and browse the boutique that is now running. If that's not
good enough, the following notification is Locust on http://0.0.0.0:8089. You
can open this and see Locust waiting to start a new load test.

## Shutdown

In event the cluster needs to be shutdown for later use, executing [stop_rke2.sh](../../rke2/stop_rke2.sh)
will halt the cluster. Process crash errors are expected.

```
$ bash rke2/stop_rke2.sh 
Stopping: generic-rke2-agent-1
Stopping generic-rke2-agent-1 |[2023-04-06T23:36:13.824] [error] [generic-rke2-agent-1] process error occurred Crashed
Stopping: generic-rke2-agent-2                                                  
Stopping generic-rke2-agent-2 |[2023-04-06T23:36:30.344] [error] [generic-rke2-agent-2] process error occurred Crashed
Stopping: generic-rke2-master-1                                                 
Stopping generic-rke2-master-1 -[2023-04-06T23:36:46.097] [error] [generic-rke2-master-1] process error occurred Crashed
```

## Restart

In order to restart, simply execute [setup_rke2.sh](../../rke2/setup_rke2.sh) as
above. Errors to connect on restart are expected. You may also increase master
or agent node count, and as long as NAME and TOKEN are the same value original
value, the nodes will be added.

```
$ bash rke2/setup_rke2.sh 
...
Context "generic-rke2-cluster" created.
rke2 setup complete
NAME                    STATUS   ROLES                       AGE     VERSION
generic-rke2-agent-1    Ready    <none>                      10m     v1.24.12+rke2r1
generic-rke2-agent-2    Ready    <none>                      8m28s   v1.24.12+rke2r1
generic-rke2-agent-3    Ready    <none>                      2m26s   v1.24.12+rke2r1
generic-rke2-master-1   Ready    control-plane,etcd,master   17h     v1.24.12+rke2r1
Please configure rancher.test to resolve to 192.168.205.2
```

## Cleaning Up

When the cluster is no longer necessary, such as good developer hygiene commit
and destroy, the cluster can be terminated by executing [remove_rke2.sh](../../rke2/remove_rke2.sh).
Errors with process crashes are expected:

```
$ bash rke2/remove_rke2.sh 
deleted context generic-rke2-cluster from /Users/jcook/.kube/config
Deleting: generic-rke2-agent-1
[2023-04-06T22:55:03.502] [error] [generic-rke2-agent-1] process error occurred Crashed
Deleting: generic-rke2-agent-2
[2023-04-06T22:55:18.862] [error] [generic-rke2-agent-2] process error occurred Crashed
Deleting: generic-rke2-master-1
[2023-04-06T22:55:34.256] [error] [generic-rke2-master-1] process error occurred Crashed
```
