# OpenShift Install

Note: if you are using a proxy, you may experience issues such as 
`INFO response 500 500 Internal Server Error –`. In this case, need to
investigate your environment, or if you have the luxury, completely unset proxy
environment variables, e.g., `unset $(compgen -e | grep -i proxy)`.

1. [Download and install OpenShift Local](https://console.redhat.com/openshift/create/local)

2. [Setup and start OpenShift Local](https://access.redhat.com/documentation/en-us/red_hat_openshift_local/2.5/html/getting_started_guide/using_gsg)

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
$ eval $(crc oc-env)
$ eval $(crc podman-env)
```

## Monitoring

Cluster monitoring is disabled by default in OpenShift Local. To enable, 
`crc config set enable-cluster-monitoring true` must be configured prior to
starting the instance.

## References

* [Installing OCP on any platform](https://docs.openshift.com/container-platform/4.10/installing/installing_platform_agnostic/installing-platform-agnostic.html)
* [OpenShift Local Create](https://console.redhat.com/openshift/create/local)
* [Platform agnostic installer](https://console.redhat.com/openshift/install/platform-agnostic)
* [Starting monitoring](https://crc.dev/crc/#starting-monitoring_gsg)