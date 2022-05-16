# Restore IPTables Rules

In order for conntrack to work in the network stack, there needs to be a rule
to enable this.

## Build and Install

Build the handy little init container like so:

```
$ docker build -t localhost:5000/jhcook/conntrack-network-init .
```

And now push it to the registry:

```
$ docker push localhost:5000/jhcook/conntrack-network-init:latest
```

Finally, pop an initcontainer stanza in the workload like so:

```
      initContainers:
        - name: conntrack-networking
          image: localhost:5000/jhcook/conntrack-network-init:latest
          resources: {}
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          imagePullPolicy: Always
          securityContext:
            capabilities:
              add:
                - NET_ADMIN
            privileged: true
```

## Resources
* https://venilnoronha.io/hand-crafting-a-sidecar-proxy-and-demystifying-istio