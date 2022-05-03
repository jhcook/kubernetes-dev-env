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
]NAME                 STATUS   ROLES                  AGE     VERSION
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
installed applications are easily usable.

```
$ bash kind/install_ingress.sh
```
