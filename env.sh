#!/usr/bin/env bash
#
# Copyright 2022-2023 Justin Cook
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
shopt -s extglob
shopt -s expand_aliases

# Set the runtime. Supported options are minikube, crc, rdctl, microk8s, and
# rke2.
export RUNTIME="minikube"
#export RUNTIME="crc"
#export RUNTIME="rdctl"
#export RUNTIME="microk8s"
#export RUNTIME="rke2"
#export RUNTIME="vagrant"

# Set loglevel to screen. The valid options are INFO and DEBUG
export LOGLEVEL="DEBUG"

# The temp directory to store dynamically created and downloaded artefacts
K8STMPDIR="$(pwd)/tmp"
export K8STMPDIR

# Pod network CIDR
export POD_NET_CIDR="172.16.0.0/16"

# Minikube IP Network Subnets
export SERVICECLUSTERIPRANGE="10.96.0.0/12"
export HOSTONLYCIDR="192.168.59.0/24"
export MINIKUBEKVM2DRIVER="192.168.39.0/24"
export MINIKUBEDOCKERCLST1="192.168.49.0/24"
export MINIKUBENODENET="192.168.205.0/24"

# shellcheck source=platform.sh
source platform.sh

# Which namespace will the project reside?
export PROJECT_NAMESPACE="boutique"

# Is the environment running?
export RUNNING=false

# Trap and ignore signals as appropriate
trap "" USR1 USR2

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
fi

# A utility function used to print in accordance with LOGLEVEL
printer() {
  if [ -n "${1-}" ]
  then
    case "${LOGLEVEL-}" in
      "DEBUG") printf "%b" "${1}" ;;
      *) printf "%b" "${1}" 2>/dev/null ;;
    esac
  fi
}

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
    export PROMETHEUS_SVC="thanos-querier"
    export PROMPORT="9092"
  else # Rancher
    export PROMETHEUS_NS="cattle-monitoring-system"
    export PROMETHEUS_SVC="rancher-monitoring-prometheus"
    export PROMPORT="9090"
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
    export IGNORE_DOCKER_CONFIG=false
  fi
}

CMDS=$(cat - <<__EOF__
check_dependencies
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
