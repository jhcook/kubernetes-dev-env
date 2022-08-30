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

## SSH into OpenShift Local complains about too many authentication failures

You may receive this error:

```
$ ssh -i ~/.crc/machines/crc/id_ecdsa -o StrictHostKeyChecking=no core@$(crc ip) -p2222
The fingerprint for the ED25519 key sent by the remote host is
SHA256:sl8U//UMvt6qe6Ypct0l7K1jGZWaekaRZfHE9oRrUTM.
Please contact your system administrator.
Add correct host key in /Users/jcook/.ssh/known_hosts to get rid of this message.
Offending ECDSA key in /Users/jcook/.ssh/known_hosts:9
Password authentication is disabled to avoid man-in-the-middle attacks.
Keyboard-interactive authentication is disabled to avoid man-in-the-middle attacks.
UpdateHostkeys is disabled because the host key is not trusted.
Received disconnect from 127.0.0.1 port 2222:2: Too many authentication failures
Disconnected from 127.0.0.1 port 2222
```
The solution is to use `IdentitiesOnly=yes` flag:

```
ssh -i ~/.crc/machines/crc/id_ecdsa -o StrictHostKeyChecking=no -o IdentitiesOnly=yes core@$(crc ip) -p2222
```

## How can I inject a root CA into the host bundle?

Add the cert to `/etc/pki/ca-trust/source/anchors` and restart
`coreos-update-ca-trust.service`. It will be added to
`/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem`. 

### References

* [How to fix "SSH Too Many Authentication Failures" Error](https://www.tecmint.com/fix-ssh-too-many-authentication-failures-error/)
* [Recommended way of adding CA Certificate](https://discussion.fedoraproject.org/t/recommended-way-of-adding-ca-certificates/15974/4)