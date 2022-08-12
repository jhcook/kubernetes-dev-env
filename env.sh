#!/usr/bin/env bash
#
# Copyright 2022 Justin Cook
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# These are entries to configure and modify the environment for code in this
# project.
#
# Author: Justin Cook

set -o nounset errexit

# Set the runtime. Supported options are minikube and crc.
export RUNTIME="minikube"
#export RUNTIME="crc"

# Set loglevel to screen. The valid options are INFO and DEBUG
export LOGLEVEL="DEBUG"

# Pod network CIDR
export POD_NET_CIDR="172.16.0.0/16"

# Which namespace will the project reside?
export PROJECT_NAMESPACE="boutique"

# Is the environment running?
export RUNNING=false

_exit_() {
  local lc="$BASH_COMMAND" rc=$?
  if [ "${LOGLEVEL}" = "DEBUG" ]
  then
    echo "Exited with code [$rc]: [$lc]"
  fi
  tty -s
}

trap _exit_ EXIT

if [ "${LOGLEVEL-}" = "DEBUG" ]
then
  set -x
  REDIRECT=""
else
  REDIRECT=">/dev/null"
fi

# Check if all the necessary utilities are available or exit
# `kubectl` is unnecessary in this context as it is later aliased
check_dependencies() {
  for cmd in "${RUNTIME}" "helm" "git" "virtualenv" "yq" "jq"
  do
    if ! command -v "${cmd}" &> /dev/null
    then
        echo "command: ${cmd} could not be found"
        exit 1
    fi
  done
}

# Changes in versioning with an independently installed kubectl utility can
# cause unexpected outcomes with API access. The assumption is Kubernetes is on
# Minikube or OpenShift Local.
check_platform() {
  if [ "${RUNTIME}" == "minikube" ]
  then
    if (which minikube && minikube status)
    then
      RUNNING=true
    fi
    alias kubectl="minikube kubectl --"
  elif [ "${RUNTIME}" = "crc" ]
  then
    if (which crc && crc status)
    then
      RUNNING=true
      #shellcheck disable=SC2046
      eval $(crc oc-env)
    fi
    alias kubectl="oc"
  else
    alias kubectl="kubectl --kubeconfig=kubeconfig --insecure-skip-tls-verify=true"
    RUNNING=true
  fi
}

# Create the namespace
create_namespace(){
  if ${RUNNING} && [ "${RUNTIME}" = "crc" ]
  then
    if ! oc get project "${PROJECT_NAMESPACE}"
    then
      oc new-project "${PROJECT_NAMESPACE}" \
        --description="This is the Google Boutique microservices demo" \
        --display-name="Online Boutique"
    fi
    oc adm policy add-scc-to-user privileged system:serviceaccount:"${PROJECT_NAMESPACE}":default
  elif ${RUNNING}
  then
    kubectl create ns "${PROJECT_NAMESPACE}" --dry-run=client -o yaml | \
    kubectl apply -f -
  fi
}

# Set the default namespace to PROJECT_NAMESPACE
set_default_namespace() {
  if ${RUNNING}
  then
    kubectl config set-context --current --namespace="${PROJECT_NAMESPACE}"
  fi
}

# Prometheus namespace and service names
set_prometheus_names() {
  if [ "${RUNTIME}" = "crc" ]
  then # OpenShift
    export PROMETHEUS_NS="openshift-monitoring"
    export PROMETHEUS_SVC="prometheus-operated"
  else # Rancher
    export PROMETHEUS_NS="cattle-monitoring-system"
    export PROMETHEUS_SVC="rancher-monitoring-prometheus"
  fi
}

# Where is Docker available, and what port should be forwarded?
set_docker_env() {
  if ${RUNNING} && [ "${RUNTIME}" = "crc" ]
  then
    #shellcheck disable=SC2046
    eval $(crc podman-env)
    export IGNORE_DOCKER_CONFIG=true
  else
    export DOCKER_HOST="tcp://localhost:2375"
    export DOCKER_REG_PORT="5000"
  fi
}

CMDS=$(cat - <<__EOF__
check_dependencies
check_platform
create_namespace
set_default_namespace
set_prometheus_names
set_docker_env
__EOF__
)

for cmd in ${CMDS}
do
  #shellcheck disable=SC2046
  eval $(printf '%s' "${cmd} ${REDIRECT-}")
done