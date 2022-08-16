# OpenShift HPA

As of OCP 4.11, automatically scaling pods based on custom metrics is provided
by the [custom metrics autoscaler](https://docs.openshift.com/container-platform/4.11/nodes/pods/nodes-pods-autoscaling-custom.html) and is in _Tech Preview_.

## Operations

An OpenShift environment needs to be available with`oc` and `kubectl` logged
in to the kube-apiserver. 

## Installation

Create the following objects:

* `openshift-keda` namespace.

```
oc create namespace openshift-keda --dry-run=client -o yaml | \
  oc apply -f -
```

* Operator Group

```
$ oc create -f hpa/ocp/openshift-keda-operator-group.yaml -n openshift-keda
```

* Subscription

```
$ oc create -f hpa/ocp/openshift-keda-subscription.yaml -n openshift-keda
```

Finally, create the custom metrics autoscaler.

```
$ oc create -f hpa/ocp/custom-metrics-autoscaler.yaml -n openshift-keda
```

## References

* [Linux Capabilities in OpenShift](https://cloud.redhat.com/blog/linux-capabilities-in-openshift)
* [Linux Capabilities](https://linux.die.net/man/7/capabilities)