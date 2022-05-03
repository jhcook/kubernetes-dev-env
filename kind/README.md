# Kind

Kind runs local Kubernetes clusters with container nodes. 

https://kind.sigs.k8s.io/docs/user/quick-start/

## Getting Started

You will need Docker available. On macOS, [Colima](https://github.com/abiosoft/colima) can be used. 

```
$ brew install colima
...
$ colima start
INFO[0000] starting colima
INFO[0000] creating and starting ...                     context=vm
INFO[0099] provisioning ...                              context=docker
INFO[0099] restarting VM to complete setup ...           context=docker
INFO[0099] stopping ...                                  context=vm
INFO[0105] starting ...                                  context=vm
INFO[0125] starting ...                                  context=docker
INFO[0130] waiting for startup to complete ...           context=docker
INFO[0130] done
```

At this point, you can create a basic cluster.

```
$ brew install kind
...
$ kind  create cluster
Creating cluster "kind" ...
 ✓ Ensuring node image (kindest/node:v1.23.4) 🖼 
 ✓ Preparing nodes 📦  
 ✓ Writing configuration 📜 
 ✓ Starting control-plane 🕹️ 
 ✓ Installing CNI 🔌 
 ✓ Installing StorageClass 💾 
Set kubectl context to "kind-kind"
You can now use your cluster with:

kubectl cluster-info --context kind-kind

Have a question, bug, or feature request? Let us know! https://kind.sigs.k8s.io/#community 🙂
$ kubectl get nodes
NAME                 STATUS   ROLES                  AGE     VERSION
kind-control-plane   Ready    control-plane,master   4m58s   v1.23.4
$ kind delete cluster
Deleting cluster "kind" ...
$ colima delete
are you sure you want to delete colima and all settings? [y/N] y
INFO[0003] deleting colima
INFO[0003] deleting ...                                  context=docker
INFO[0003] deleting ...                                  context=vm
INFO[0003] done
```

## Create a Cluster for Calico

A multi-node Calico Enterprise cluster requires more resources. As such, you
will need to allocate more cpu, memory, and disk to the virtual machine when
invoking Colima. Then, you can create the cluster using the manifest provided:

```
$ colima start --cpu 6 --memory 28 --disk 50
INFO[0000] starting colima
INFO[0000] creating and starting ...                     context=vm
...
$ kind create cluster --config kind/calico_cluster.yaml 
Creating cluster "calico-cluster" ...
 ✓ Ensuring node image (kindest/node:v1.23.4) 🖼
 ✓ Preparing nodes 📦 📦 📦  
 ✓ Writing configuration 📜 
 ✓ Starting control-plane 🕹️ 
 ✓ Installing StorageClass 💾 
 ✓ Joining worker nodes 🚜 
Set kubectl context to "kind-calico-cluster"
You can now use your cluster with:

kubectl cluster-info --context kind-calico-cluster

Thanks for using kind! 😊
$ kubectl get nodes
NAME                           STATUS     ROLES                  AGE   VERSION
calico-cluster-control-plane   NotReady   control-plane,master   43s   v1.23.4
calico-cluster-worker          NotReady   <none>                 10s   v1.23.4
calico-cluster-worker2         NotReady   <none>                 10s   v1.23.4
```

# Make all nodes schedulable

If you are restricted on assets, to avoid contention, remove master node taint.

```
$ kubectl taint nodes --all node-role.kubernetes.io/master- || /usr/bin/true
node/calico-cluster-control-plane untainted
taint "node-role.kubernetes.io/master" not found
taint "node-role.kubernetes.io/master" not found
```

# Ingress

Kind clusters do not have an Ingress controller configured. So, install one and
installed applications are easily accessible. The controller is configured with
`kind` to listen on localhost:80 and localhost:443. Therefore, hostnames should
resolve to 127.0.0.1.

```
$ bash kind/install_ingress.sh
namespace/ingress-nginx created
serviceaccount/ingress-nginx created
serviceaccount/ingress-nginx-admission created
role.rbac.authorization.k8s.io/ingress-nginx created
role.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrole.rbac.authorization.k8s.io/ingress-nginx created
clusterrole.rbac.authorization.k8s.io/ingress-nginx-admission created
rolebinding.rbac.authorization.k8s.io/ingress-nginx created
rolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
configmap/ingress-nginx-controller created
service/ingress-nginx-controller created
service/ingress-nginx-controller-admission created
deployment.apps/ingress-nginx-controller created
job.batch/ingress-nginx-admission-create created
job.batch/ingress-nginx-admission-patch created
ingressclass.networking.k8s.io/nginx created
validatingwebhookconfiguration.admissionregistration.k8s.io/ingress-nginx-admission created
deployment.apps/ingress-nginx-controller patched (no change)
pod/ingress-nginx-controller-55c69f5f55-8c8cq condition met
```

# Rancher

Installation of Rancher on Kind can be performed as per below.

```
$ bash install_rancher.sh
...
Happy Containering!
Waiting for deployment "rancher" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment spec update to be observed...
Waiting for deployment "rancher" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "rancher" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "rancher" rollout to finish: 2 of 3 updated replicas are available...
deployment "rancher" successfully rolled out
```

# Monitoring

```
$ bash install_monitoring.sh
...
Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.
deployment "rancher-monitoring-grafana" successfully rolled out
deployment "rancher-monitoring-kube-state-metrics" successfully rolled out
deployment "rancher-monitoring-operator" successfully rolled out
deployment "rancher-monitoring-prometheus-adapter" successfully rolled out

$ bash monitoring/configure_prometheus.sh
service/typha-metrics created
service/calico-controllers-metrics created
felixconfiguration.projectcalico.org/default patched
service/felix-metrics created
service/ingress-nginx-controller patched
service/ingress-nginx-controller patched
service/ingress-nginx-controller patched
service/ingress-nginx-controller patched
deployment.apps/ingress-nginx-controller patched
deployment.apps/ingress-nginx-controller patched
deployment.apps/ingress-nginx-controller patched
servicemonitor.monitoring.coreos.com/calico-typha-prometheus-config created
servicemonitor.monitoring.coreos.com/calico-kube-controllers-prometheus-config created
servicemonitor.monitoring.coreos.com/calico-svc-monitoring-prometheus-config created
servicemonitor.monitoring.coreos.com/ingress-nginx-monitoring-config created

$ bash monitoring/configure_grafana_dashboards.sh
Applying Grafana dashboard: monitoring/dashboards/calico-grafana-dashboards.yaml
configmap/calico-dashboards created
Applying Grafana dashboard: monitoring/dashboards/nginx-grafana-dashboards.yaml
configmap/nginx-dashboards created
```

# Calico Enterprise

Installation of the Calico Enterprise suite can be performed on the Kind
cluster as per below. The `calico-enterprise-license.yaml` and `tigera-pull-secret.json`
need to be resident in `calico_enterprise` directory.

```
$ bash calico_enterprise/install_calico_enterprise.sh
...
Visit https://localhost:9443/ to login to the Calico Enterprise UI with token above.
```
