# FAQ

## How do I experiment with building images on RHEL?

Get a RHEL (virtual) machine, install "Docker", and begin!

```
$ sudo yum install docker
...
$ docker run --rm --user 0 -ti registry.access.redhat.com/ubi8/python-39 -- bash
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
* githubusercontent.com
* registry.redhat.io
* registry.access.redhat.com
* cdn-ubi.redhat.com
* dl.fedoraproject.org
* mirrors.fedoraproject.org
