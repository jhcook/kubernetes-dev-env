# Configuration

Configuration of the environment is largely performed via [`env.sh`](../../env.sh) in the root
directory.

In order to decouple components, an effort is made to use native Kubernetes
components and only provide configuration as to the opinion of each item and
those chosen by the operator. 

## Configuration Items

`env.sh` is sourced by other code in the project, and is the central point of
configuration. By default, it assumes `minikube` is used and as such searches
the user PATH for `minikube` and other utilities required for the runtime such
as `helm`, `git`, `virtualenv`, `yq`, and `jq`. It then aliases `kubectl` as
`minikube kubectl`. Users may edit this piece of code for any custom uses of
`kubectl`.

`env.sh` supports [OpenShift Local](https://developers.redhat.com/products/openshift-local/overview) via [`crc`](https://crc.dev/crc/). In order to use this capability,
one needs to create a [Red Hat developer account](https://developers.redhat.com/blog/2016/03/31/no-cost-rhel-developer-subscription-now-available#), [download and install](https://console.redhat.com/openshift/create/local), and
[configure the cluster](https://access.redhat.com/documentation/en-us/red_hat_openshift_local/2.5/html/getting_started_guide/configuring_gsg). In order to
use OpenShift Local in the project, `RUNTIME` in `env.sh` needs to be "crc".

`LOGLEVEL` can be set to "INFO" or "DEBUG". This setting is straightforward,
and "DEBUG" increases verbosity of output in the code.

`POD_NET_CIDR` defaults to "172.16.0.0/16" but is configurable by editing this
variable.

`PROJECT_NAMESPACE` is set to "boutique" by default. It is used to manage the
namespace across the project.

In an effort to provide support for TCP proxy for localhost forwarding to
Minikube, `DOCKER_REG_PORT` is set to 5000. For platforms this unnecessary,
the user can ignore or provide custom code to meet their use case.

There are use cases custom images will need to be pushed to a registry, and the
examples included use Minishift registry addon. This is defined as the well
known `DOCKER_HOST` variable. Support for integrated registries such as
OpenShift is provided. The user can modify according to their use case --
`eval $(crc podman-env)`. In this case, `IGNORE_DOCKER_CONFIG` needs to be set
as `true`.
