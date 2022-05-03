# tcp-exporter

## Introduction

This sidecar uses conntrack or sampling to provide a count of TCP connections
that are ESTABLISHED state. It provides Prometheus metrics scraped at the 
endpoint http://x.x.x.x:9100/metrics by default. 

These metrics provide insight and can be used, for instance, with Keda which
provides a base or ScaledObject(s).

## Build

In the `sidecar` (this) directory, you will notice a `Dockerfile` and
`tcp_exporter.py`. These file can be used with `docker build ...` or another
utility such as `podman build ...` to build an image. An example is displayed
below.

This example uses Colima on macOS:

```
$ limactl start default
...
$ alias docker="lima nerdctl"
```

At this point, you will have a running environment one can use to build the
artefact (image) and push to the registry on Minikube. You need to provide
a route from your host to Minikube like so:

```
$ docker run --rm -it --network=host alpine ash -c "apk add socat && socat TCP-LISTEN:5000,reuseaddr,fork TCP:$(minikube ip):5000"
...
```

Now, let's build and push the image to our local registry. You will need to
leave the above running and switch to another window, or perhaps you're clever
enough to have spawned a daemon:

```
$ docker build -t localhost:5000/jhcook/tcp-exporter .
[+] Building 3.2s (8/8) FINISHED                                                                  
...
unpacking localhost:5000/jhcook/tcp-exporter:latest (sha256:94dc80bd667c6cad4e89e1ff4b31903447a98c63cb11ab2af9d098ae8a97db6b)...done
$ docker push localhost:5000/jhcook/tcp-exporter:latest
INFO[0000] pushing as a reduced-platform image (application/vnd.docker.distribution.manifest
...
elapsed: 6.2 s                                                                    total:  20.0 M (3.2 MiB/s) 
```

## Run

The utility requires conntrack and CAP_NET_ADMIN capability to run efficiently
and provide an accurate count. If this is not available, the utility will fall
back to sampling from userspace which is less accurate although still useful.

The code can be executed like the following for more insight:

```
$ ./tcp_exporter.py 
usage: tcp_exporter.py <LISTEN_PORT> <WATCH_PORT>

example: tcp_exporter.py 9100 8080
```


```
$ python3 tcp_exporter.py 9100 8080
Server started at localhost: 9100
127.0.0.1 - - [29/Mar/2022 10:20:23] "GET /metrics HTTP/1.1" 200 -
```

## Container

This solution was designed for Kubernetes, and as such is intended to be run in
a sidecar along the primary application. If you've got the container pushed to
a registry, you can patch your Deployment spec as follows to provide the
metrics.

```
  # kubectl patch --patch-file does not accept here docs :-/
  cat << EOF >/tmp/$$.tmp
spec:
  template:
    spec:
      containers:
      - name: tcp-exporter
        image: localhost:5000/jhcook/tcp-exporter:latest
        imagePullPolicy: IfNotPresent
        securityContext:
          capabilities:
            add: ["NET_ADMIN"]
        args: ["9100", "${SVCPORT}"]
        ports:
          - containerPort: 9100
            protocol: TCP
EOF
  kubectl patch "${deploy}" -n default --patch-file /tmp/$$.tmp
```
For more information, and an example used with Keda for scaling, please see
`hpa/configure_hpa.sh` in this repository.
