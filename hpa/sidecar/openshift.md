# OpenShift Builds

The OpenShift method of creating builds and making them available via the
integrated registry is creating `BuildConfig`s and `ImageStream`s. Fetching source
from Git and the use of Dockerfiles are supported. As such, each image can be
made available by building from source.

Create the Kubernetes objects for each image. In the case of this module, each
directory has `ocp-*.yaml` files and can be easily created:

```
$ for f in hpa/sidecar/*/ocp-*.yaml ; do kubectl apply -f $f ; done
buildconfig.build.openshift.io/conntrack-network-init-image created
imagestream.image.openshift.io/conntrack-network-init created
buildconfig.build.openshift.io/tcp-exporter-image created
imagestream.image.openshift.io/tcp-exporter created
```

Once created, enable image lookup for all resources in the project with
`oc set image-lookup ...`. 

Next, each build needs to be initiated using `oc start-build ...` like so:

```
oc start-build tcp-exporter-image -F
```

> Tip
If you are using a proxy with HTTPS filtering, you will need to
create exceptions for github.com and alpinglinux.org for this example. If you
are unable to bypass the filtering, please see [this topic](https://access.redhat.com/solutions/6165352) or
[this issue](https://github.com/alpinelinux/docker-alpine/issues/160#issuecomment-844325769) for assistance. 

## Get the image registry URL

```
$ oc get route -A -o jsonpath='{range .items[*]}{.spec.host}{"\n"}{end}' | grep image-registry
```

## Allow the insecure registry and others

In case other registries need to be supported, the following is the process
that should be followed.

```
$ oc patch --type=merge --patch='{
  "spec": {
    "registrySources": {
      "insecureRegistries": [
      "image-registry.openshift-image-registry.svc:5000"
      ]
    }
  }
}' image.config.openshift.io/cluster
```

```
$ ssh -i ~/.crc/machines/crc/id_ecdsa -o StrictHostKeyChecking=no core@$(crc ip) -p2222
crc-master $ cat /etc/containers/registries.conf
unqualified-search-registries = ['registry.access.redhat.com', 'docker.io']

[[registry]]
  location = "image-registry.openshift-image-registry.svc:5000"
  insecure = true
  blocked = false
  mirror-by-digest-only = false
  prefix = ""

```

## References

* [Adding an insecure registry](https://github.com/code-ready/crc/wiki/Adding-an-insecure-registry)
* [Using image streams with Kubernetes resources](https://docs.openshift.com/container-platform/4.10/openshift_images/using-imagestreams-with-kube-resources.html)