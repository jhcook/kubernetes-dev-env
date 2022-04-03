# Calico Enterprise

## Installation

Place your pull secret and Calico Enterprise License in this directory using
the following file names:

* quay.io pull secret: `tigera-pull-secret.json`
* Calcio Enterprise License: `calico-enterprise-license.yaml`

Git is configured to ignore these filenames. 

Execute `calico_enterprise/install_calico_enterprise.sh` and after some time,
you will be prompted to open a window to the UI:

```
Visit https://localhost:9443/ to login to the Calico Enterprise UI with token above.

Forwarding from 127.0.0.1:9443 -> 9443
Forwarding from [::1]:9443 -> 9443
```

## Prometheus

If Rancher is installed with monitoring, the Calico Enterprise installation
will use the Rancher Prometheus operator to manage the AlertManager and
Prometheus CRs in the `tigera-prometheus` namespace.

If no Prometheus operator exists, or is in an unknown namespace, the pull
secret and operator patch will not be successful.

If other Prometheus instances will need to be deployed alongside Tigera, then
modification to the operator args will be necessary. By default, they are the
following:

```
      - args:
        - --prometheus-config-reloader=quay.io/tigera/prometheus-config-reloader:v3.13.0
        - --config-reloader-memory-request=25Mi
        - --namespaces=tigera-prometheus
        - --cluster-domain=cluster.local
```
## Post Configuration



## Resources
* [Calico Enterprise Installation](https://docs.tigera.io/getting-started/kubernetes/generic-install)
* [Calico Resources](https://docs.tigera.io/reference/resources/)
* [Configure access to Calico Enterprise Manager UI](https://docs.tigera.io/getting-started/cnx/access-the-manager)
* [Prometheus Support](https://docs.tigera.io/maintenance/monitor/support)
