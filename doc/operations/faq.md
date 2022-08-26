# FAQ

## How do I experiment with building images on RHEL?

Get a RHEL (virtual) machine, install "Docker", and begin! On a RHEL host:

```
$ sudo yum install docker
...
```

On a single node Minishift cluster:

```
$ eval $(minikube docker-env)
```

On OpenShift Local:

```
$ eval $(crc podman-env)
```

If you exported `podman` environment, please use that with the following: s

```
$ docker run --rm --user 0 -ti registry.access.redhat.com/ubi8/python-39 -- bash
```

## How do I build the images for OCP?

With OpenShift Local, export the Podman environment.

```
$ eval $(crc podman-env)
```

As an example, in the `hpa/sidecar` subdirectories, you can see examples in
each context. In the case of ocp, you build using the context of the container
directory:

```
$ podman build -t tcp-exporter -f ocp/Dockerfile .
```

## How do I delete a lot of images in OpenShift?

From time to time you will need to clean up images that have collected due to
development -- primarily.

```
$ oc delete image $(oc get images -o jsonpath='{range .items[*]}{.dockerImageReference} {.dockerImageMetadata.Created} {.dockerImageMetadata.Size}{"\n"}{end}' -n boutique | sed 's/@/ /' | grep 2022-08 | awk '{print$2}')
```

## What domains should I exempt from a HTTPS filtering proxy?

* github.com
* alpinelinux.org
* ghcr.io
* k8s.ghcr.io
* githubusercontent.com
* registry.redhat.io
* registry.access.redhat.com
* cdn-ubi.redhat.com
* dl.fedoraproject.org
* mirrors.fedoraproject.org
* fedora.mirrorservice.org
