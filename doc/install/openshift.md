# OpenShift Install

Note: if you are using a proxy, you may experience issues such as 
`INFO response 500 500 Internal Server Error –`. In this case, need to
investigate your environment, or if you have the luxury, completely unset proxy
environment variables, e.g., `unset $(compgen -e | grep -i proxy)`.

1. [Download and install OpenShift Local](https://console.redhat.com/openshift/create/local)

2. [Setup and start OpenShift Local](https://access.redhat.com/documentation/en-us/red_hat_openshift_local/2.5/html/getting_started_guide/using_gsg)

## Quickstart

Please have a look at [`setup_ocp.sh`](../../ocp/setup_ocp.sh). You once
OpenShift Local is installed, you my `bash ./ocp/setup_ocp.sh` and the single-
node cluster will be running locally.

```
$ crc setup
...
$ crc config set memory 30208
...
$ crc config set disk-size 100
...
$ crc config set enable-cluster-monitoring true
Successfully configured enable-cluster-monitoring to true
$ crc start
...
```

After running, you will need to add `oc` to PATH and update the environment
with the Podman data.

```
$ eval $(crc oc-env)
$ eval $(crc podman-env)
```

## Monitoring

Cluster monitoring is disabled by default in OpenShift Local. To enable, 
`crc config set enable-cluster-monitoring true` must be configured prior to
starting the instance. [`setup_ocp.sh`](../../ocp/setup_ocp.sh) does this.

Enable user workload monitoring, and set reasonable values for a development
environment.

```
$ kubectl apply -f ./ocp/cluster-monitoring-config.yaml 
configmap/cluster-monitoring-config created
```

## Troubleshooting

To gain access to the machine, try the following ssh command:

```
$ ssh -i '~/.crc/machines/crc/id_ecdsa' -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -o ConnectTimeout=3 -p 2222 core@$(crc ip)
Red Hat Enterprise Linux CoreOS 412.86.202303211731-0
  Part of OpenShift 4.12, RHCOS is a Kubernetes native operating system
  managed by the Machine Config Operator (`clusteroperator/machine-config`).

WARNING: Direct SSH access to machines is not recommended; instead,
make configuration changes via `machineconfig` objects:
  https://docs.openshift.com/container-platform/4.12/architecture/architecture-rhcos.html

---
[core@crc-8tnb7-master-0 ~]$ 
```

Accessing the OpenShift cluster by CLI on the machine can be achieved as
follows:

```
[core@crc-8tnb7-master-0 ~]$ oc --context admin --cluster crc --kubeconfig /opt/kubeconfig get deploy -A
...
```
## References

* [Installing OCP on any platform](https://docs.openshift.com/container-platform/4.10/installing/installing_platform_agnostic/installing-platform-agnostic.html)
* [OpenShift Local Create](https://console.redhat.com/openshift/create/local)
* [Platform agnostic installer](https://console.redhat.com/openshift/install/platform-agnostic)
* [Starting monitoring](https://crc.dev/crc/#starting-monitoring_gsg)