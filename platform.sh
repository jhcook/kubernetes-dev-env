#!/usr/bin/env bash
#
# Copyright 2023 Justin Cook
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
# These are aliases that need to be sourced based on platform -- for sake of
# simplicity. There are other variables here as well.
# https://superuser.com/questions/708462/alias-scoping-in-bash-functions
#
# Author: Justin Cook

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
    if minikube status 2>/dev/null
    then
        RUNNING=true
    else
        RUNNING=false
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
elif [ "${RUNTIME}" = "rdctl" ]
then
    if rdctl shell "id" 2>/dev/null
    then
        case :$PATH: in 
        *:$HOME/.rd/bin:*) ;; 
        *) export PATH=$HOME/.rd/bin:$PATH ;;
        esac
        RUNNING=true
    else
        RUNNING=false
    fi
elif [ "${RUNTIME}" = "microk8s" ]
then
    #alias kubectl="microk8s kubectl --"
    if microk8s status 2>/dev/null
    then
        RUNNING=true
        #export KUBECONFIG="${HOME}/.kube/config-microk8s"
    else
        RUNNING=false
    fi
elif [ "${RUNTIME}" = "rke2" ]
then
    alias rke2="multipass"
    MULTIPASSCMD="$(command -v multipass)"
    RUNNING=false
else
    alias kubectl="kubectl --kubeconfig=kubeconfig --insecure-skip-tls-verify=true"
    #shellcheck disable=SC2034
    RUNNING=true
fi