#!/usr/bin/env bash
#
# Disable eBPF and switch to kube-proxy

# shellcheck source=/dev/null
. env.sh

# Switch dataplane to Iptables
kubectl patch installation.operator.tigera.io default --type merge -p '{"spec":{"calicoNetwork":{"linuxDataplane":"Iptables"}}}'

# Reenable kube-proxy
kubectl patch ds -n kube-system kube-proxy --type merge -p '{"spec":{"template":{"spec":{"nodeSelector":{"non-calico": null}}}}}'
