# Microservices Demo

The code below creates a virtual Python3 environment, clones Google's
microservices-demo, installes the Kubernetes release manifests, and ends with
instructions on how to access the demo application and Locust load generator.

## Dependencies

The platform requires Python3 and virtualenv, Git, and `kubectl` to be
installed and available in PATH.

Access to a running Kubernetes cluster with KUBECONFIG context configured and
appropriate access granted.

## Installation

Execute the following script. Please note, the script does not exit. Exiting
the runtime will kill Locust (load generator), but the Online Boutique will
continue to be available as usual.

```
$ bash app/install_boutique.sh
...
app/microservices-demo
deployment.apps/emailservice created
service/emailservice created
deployment.apps/checkoutservice created
service/checkoutservice created
deployment.apps/recommendationservice created
service/recommendationservice created
deployment.apps/frontend created
service/frontend created
service/frontend-external created
deployment.apps/paymentservice created
service/paymentservice created
deployment.apps/productcatalogservice created
service/productcatalogservice created
deployment.apps/cartservice created
service/cartservice created
deployment.apps/loadgenerator created
deployment.apps/currencyservice created
service/currencyservice created
deployment.apps/shippingservice created
service/shippingservice created
deployment.apps/redis-cart created
service/redis-cart created
deployment.apps/adservice created
service/adservice created
Waiting for deployment spec update to be observed...
Waiting for deployment spec update to be observed...
Waiting for deployment "adservice" rollout to finish: 0 of 1 updated replicas are available...
deployment "adservice" successfully rolled out
deployment "cartservice" successfully rolled out
deployment "checkoutservice" successfully rolled out
deployment "currencyservice" successfully rolled out
deployment "emailservice" successfully rolled out
deployment "frontend" successfully rolled out
deployment "loadgenerator" successfully rolled out
deployment "paymentservice" successfully rolled out
deployment "productcatalogservice" successfully rolled out
deployment "recommendationservice" successfully rolled out
deployment "redis-cart" successfully rolled out
deployment "shippingservice" successfully rolled out
ingress.networking.k8s.io/frontend-ingress created

Please configure name resolution boutique.test to master's IP.

Open browser to: http://boutique.test

[2023-04-11 11:55:24,119] jcmmini1.local/INFO/locust.main: Starting web interface at http://0.0.0.0:8089 (accepting connections from all network interfaces)
[2023-04-11 11:55:24,137] jcmmini1.local/INFO/locust.main: Starting Locust 2.15.1
```

## Configuration

Depending on the platform, name resolution may be required.

Individual names may be configured in '/etc/hosts' on a Unix-based platform.

```
$ grep .test /etc/hosts
192.168.205.5 rancher.test
192.168.205.5 boutique.test
```

If using Minikube with the ingress-dns addon, boutique.test will be resolved as
expected if domain 'test' nameserver is the Minikube IP address.

For example, on macOS:

```
$ cat /etc/resolver/minikube-test 
domain test
nameserver 192.168.205.5
search_order 1
timeout 5
```
