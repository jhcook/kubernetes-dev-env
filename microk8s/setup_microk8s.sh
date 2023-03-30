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
#. env.sh

set -o errexit nounset

K8SVER="1.24/stable"

# Ensure dependencies available
for cmd in "microk8s" "multipass" "jq"
do
    if ! command -v "${cmd}" > /dev/null 2>&1
    then
        echo "command: ${cmd} could not be found"
        exit 1
    fi
done

# Save the "old" STDOUT and redirect any output to STDOUT to /dev/null
#exec 3>&1
#exec 1> debug.log

# Install microk8s and wait until ready
# The hard way: https://microk8s.io/docs/install-multipass
echo "Installing microk8s"
microk8s install
microk8s status --wait-ready

# Configure microk8s to use correct Kubernetes version
# https://microk8s.io/docs/setting-snap-channel

# Remove motd from the master as it's too noisy
# https://stackoverflow.com/questions/41706150/commenting-out-lines-in-a-file-using-a-bash-script
echo "sudo sed -i '/^session    optional     pam_motd\.so/s/^/#/' /etc/pam.d/sshd" |\
multipass shell microk8s-vm 2>/dev/null

# Get the version of microk8s snap and configure if mismatched
ver=$(echo "snap list microk8s" | multipass shell microk8s-vm | tail -n1 | awk '{print$4}')
if [ "${ver:=0}" != "${K8SVER}" ]
then
    echo "Configuring microk8s to use ${K8SVER}"
    echo "sudo snap refresh microk8s --classic --channel=${K8SVER}" | \
        multipass shell microk8s-vm | grep microk8s
    echo "Restarting microk8s"
    microk8s stop
    microk8s start
    microk8s status --wait-ready
fi

# Voila! And enable the correct services
echo "Enabling DNS and internal Registry"
microk8s enable dns registry

# Helm addon is not reliable. So, export kubeconfig.
if [ ! -d "${HOME}/.kube" ]
then
    mkdir "${HOME}/.kube"
fi
microk8s config > "${HOME}/.kube/microk8s.conf"
chmod 0700 "${HOME}/.kube/microk8s.conf"
export KUBECONFIG="${HOME}/.kube/microk8s.conf"

# Create node(s), configure, and add to cluster
# https://microk8s.io/docs/clustering
# https://microk8s.io/docs/install-multipass

NODECMDS=$(cat <<__CMD__
sudo snap install microk8s --classic --channel="${K8SVER}"
sudo iptables -P FORWARD ACCEPT
sudo usermod -a -G microk8s ubuntu
newgrp microk8s
__CMD__
)

for node in microk8s-vm-node{1..2}
do
    if multipass info "${node}" 2>/dev/null ; then continue ; fi
    echo "Creating ${node}"
    multipass launch --name "${node}" --memory 8G --disk 40G
done

for node in microk8s-vm-node{1..2}
do
    # Remove motd from the node as it's too noisy 
    # https://stackoverflow.com/questions/41706150/commenting-out-lines-in-a-file-using-a-bash-script
    echo "sudo sed -i '/^session    optional     pam_motd\.so/s/^/#/' /etc/pam.d/sshd" |\
    multipass shell "${node}" 2>/dev/null
    # Get the version of microk8s snap and configure if mismatched
    ver=$(echo "snap list microk8s" | multipass shell "${node}" | tail -n1 | awk '{print$4}')
    if [ "${ver:=0}" != "${K8SVER}" ]
    then
        echo "Configuring ${node}"
        echo "${NODECMDS}" | multipass shell "${node}"
        echo "Restarting ${node}"
        multipass stop "${node}"
        multipass start "${node}"
    fi
done

# Join node(s) and create a Kubernetes cluster
for node in microk8s-vm-node{1..2}
do
    if kubectl get "node/${node}" 2>/dev/null ; then continue ; fi
    # Get the node's IP address
    NIP=$(multipass info "${node}" --format json | jq -r ".info.\"${node}\".ipv4[0]")
    # Add worker to /etc/hosts on master
    echo "sudo bash -c \"echo ${NIP} ${node} | cat - >>/etc/hosts\"" |\
        multipass shell microk8s-vm
    # Get a token to add node on master
    microk8s add-node | grep "microk8s join\ .*\ --worker" | \
        multipass shell "${node}"
done

kubectl wait --for=condition=Ready nodes --all
microk8s enable ingress
kubectl rollout status ds/nginx-ingress-microk8s-controller -n ingress

# Turn off redirect by reverting STDOUT
#exec 1>&3-