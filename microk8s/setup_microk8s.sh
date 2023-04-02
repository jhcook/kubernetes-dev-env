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
# Setup microk8s for use within this code base.

# shellcheck source=/dev/null
. env.sh

set -o errexit nounset

K8SVER="1.24/stable"
KUBECTL="$(which kubectl)"
LOCALKUBECONFIG="${HOME}/.kube/config-microk8s"

# Ensure dependencies available
for cmd in "microk8s" "multipass" "jq"
do
    if ! command -v "${cmd}" > /dev/null 2>&1
    then
        echo "command: ${cmd} could not be found"
        exit 1
    fi
done

NODECMDS=$(cat <<__CMD__
sudo snap install microk8s --classic --channel="${K8SVER}"
sudo iptables -P FORWARD ACCEPT
sudo usermod -a -G microk8s ubuntu
newgrp microk8s
__CMD__
)

# Install microk8s and wait until ready
# The hard way: https://microk8s.io/docs/install-multipass
# https://microk8s.io/docs/clustering
# https://microk8s.io/docs/install-multipass
for node in microk8s-vm{,-node{1,2}}
do
    if ! multipass info "${node}" 2>/dev/null
    then
        echo "Creating: ${node}"
        multipass launch --name "${node}" --memory 8G --disk 40G
    fi

    # Remove motd from the master as it's too noisy
    # https://stackoverflow.com/questions/41706150/commenting-out-lines-in-a-file-using-a-bash-script
    echo "sudo sed -i '/^session    optional     pam_motd\.so/s/^/#/' /etc/pam.d/sshd" |\
    multipass shell "${node}" | cat - >/dev/null 2>&1

    # Configure microk8s to use correct Kubernetes version
    # https://microk8s.io/docs/setting-snap-channel
    # Get the version of microk8s snap and configure if mismatched
    ver=$(echo "snap list microk8s" | multipass shell "${node}" | tail -n1 | awk '{print$4}')
    if [ "${ver:=0}" != "${K8SVER}" ]
    then
        echo "Configuring ${node} to use ${K8SVER}"
        echo "${NODECMDS}" | multipass shell "${node}"
    fi
    
    # Join node(s) to master and create a Kubernetes cluster
    if [ "${node}" != "microk8s-vm" ]
    then
        if "${KUBECTL}" get "node/${node}" 2>/dev/null ; then continue ; fi
        # Get the node's IP address
        NIP=$(multipass info "${node}" --format json | jq -r ".info.\"${node}\".ipv4[0]")
        # Add worker to /etc/hosts on master
        echo "sudo bash -c \"echo ${NIP} ${node} | cat - >>/etc/hosts\"" |\
            multipass shell microk8s-vm
        # Get a token to add node on master
        microk8s add-node | grep "microk8s\ join\ .*\ --worker" |\
            multipass shell "${node}"
        # Wait for the node to appear on the control plane
        while :
        do
            sleep 5
            if "${KUBECTL}" get node/"${node}" >/dev/null 2>&1
            then
                sleep 5
                break
            fi
        done
    else
        microk8s status --wait-ready
        # Helm addon is not reliable. So, export kubeconfig, merge with
        # existing, and set context.
        if [ ! -d "${HOME}/.kube" ]
        then
            mkdir "${HOME}/.kube"
        fi
        "${KUBECTL}" config delete-context microk8s-cluster || /usr/bin/true
        "${KUBECTL}" config delete-cluster microk8s-cluster || /usr/bin/true
        microk8s config > "${LOCALKUBECONFIG}"
        chmod 0600 "${LOCALKUBECONFIG}"
        export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}:${LOCALKUBECONFIG}"
        "${KUBECTL}" config view --flatten > "${KUBECONFIG%%:*}"
        "${KUBECTL}" config set-context microk8s-cluster --namespace default
    fi
done

# Wait for nodes to become ready
"${KUBECTL}" wait --for=condition=Ready nodes --all --timeout=600s

# Voila! Enable the correct services and wait for ingress to deploy
echo "Enabling DNS, internal registry, and ingress"
microk8s enable dns registry ingress
"${KUBECTL}" rollout status ds/nginx-ingress-microk8s-controller -n ingress
