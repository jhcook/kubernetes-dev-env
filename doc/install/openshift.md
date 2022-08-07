# OpenShift Install

Note: if you are using a proxy, you may experience issues such as 
`INFO response 500 500 Internal Server Error –`. In this case, need to
investigate your environment, or if you have the luxury, completely unset proxy
environment variables, e.g., `unset $(compgen -e | grep -i proxy)`.

1. Download and install OpenShift Local
https://console.redhat.com/openshift/create/local

2. Setup and start OpenShift Local
https://access.redhat.com/documentation/en-us/red_hat_openshift_local/2.5/html/getting_started_guide/using_gsg

```
$ crc setup
...
$ crc start
...
$ eval $(crc oc-env)
$ eval $(crc podman-env)
```
