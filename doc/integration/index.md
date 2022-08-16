# Integration

Documentation to integrate various components and applications to a variety of
Kubernetes implementations is located in this folder.

## OpenShift

OpenShift provides an opinionated set of objects, additional verbs, and secure
implementation. 

### Security Context Constraints

In order to use the standard Google Boutique microservices demo
application, the easiest method is to grant the default service account
privileged access. 

```
$ oc adm policy add-scc-to-user privileged system:serviceaccount:project1:default
```

### HTTPS Filtering

For those environments using HTTPS filtering, you will either need to get
exceptions for appropriate remote mirrors or trust the proxy CA certificate.
It must be in PEM format, and this can be achieved as follows:

```
$ openssl x509 -inform DER -in cert.cer -outform PEM -out cert.pem
```

## Resources

* [Using pods in a privileged security context](https://docs.openshift.com/container-platform/4.11/cicd/pipelines/using-pods-in-a-privileged-security-context.html)