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
shopt -s extglob

# Set the runtime. Supported options are minikube and crc.
export RUNTIME="minikube"
#export RUNTIME="crc"

# Set loglevel to screen. The valid options are INFO and DEBUG
export LOGLEVEL="DEBUG"

# Pod network CIDR
export POD_NET_CIDR="172.16.0.0/16"

# Minikube IP Network Subnets
SERVICECLUSTERIPRANGE="10.96.0.0/12"
HOSTONLYCIDR="192.168.59.0/24"
MINIKUBEKVM2DRIVER="192.168.39.0/24"
MINIKUBEDOCKERCLST1="192.168.49.0/24"
MINIKUBENODENET="192.168.205.0/24"

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

# Changes in versioning with an independently installed kubectl utility can
# cause unexpected outcomes with API access. Therefore, redirect kubectl
# to and handle proxy variables as appropriate.
check_platform() {
  if [ "${RUNTIME}" == "minikube" ]
  then
    # Installing behind a proxy or VPN can cause problems
    # https://minikube.sigs.k8s.io/docs/handbook/vpn_and_proxy/
    # If a proxy is set, then ensure specific subnets to K8s bypass the proxy.
    if [ -n "${HTTPS_PROXY:-}" ] || [ -n "${HTTP_PROXY:-}" ]
    then
      for np in no_proxy NO_PROXY
      do
        # Use inline case statements since fallthrough with ;& is not supported
        # before Bash 4.
        case ${!np:-} in
          (!(*"${SERVICECLUSTERIPRANGE}"*))
            eval ${np}+=",${SERVICECLUSTERIPRANGE}"
          ;;
        esac
        case ${!np:-} in
          (!(*"${HOSTONLYCIDR}"*))
            eval ${np}+=",${HOSTONLYCIDR}"
          ;;
          esac
          case ${!np:-} in
          (!(*"${MINIKUBEDOCKERCLST1}"*))
            eval ${np}+=",${MINIKUBEDOCKERCLST1}"
          ;;
          esac
          case ${!np:-} in
          (!(*"${MINIKUBEKVM2DRIVER}"*))
            eval ${np}+=",${MINIKUBEKVM2DRIVER}"
          ;;
          esac
          case ${!np:-} in
          (!(*"${MINIKUBENODENET}"*))
            eval ${np}+=",${MINIKUBENODENET}"
          ;;
        esac
      done
    fi
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