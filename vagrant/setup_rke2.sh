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
# Setup RKE2 with on hosts using ssh
#
# Tested on: macOS 13.3.1 with Ubuntu 22.04.2 LTS Jammy Jellyfish nodes

set -o errexit nounset
shopt -s expand_aliases

# shellcheck source=/dev/null
. env.sh
. "$(dirname "$0")/localenv.sh"

# Ignore user-defined signals
trap - USR1 USR2

# Install RKE2 on a node
# Requires: RKE2_VERSION set
#           IRT set but defaults to null
#           CONFIGYAML set which is a string of YAML
#           RKE2ROLE set which defaults to "server"
#           $1 a node name that resolves to an available server
create_rke2_node() {
    # Check if node is running correct RKE2 service
    if echo "stat /usr/local/lib/systemd/system/rke2-${RKE2ROLE:-server}.service" | ssh "${1}" > >(printer) 2> >(printer)
    then
        if echo "systemctl is-active rke2-${RKE2ROLE:-server}.service" | ssh "${1}" > >(printer) 2> >(printer)
        then
            echo "$1 is running" 
            return
        else
            echo "sudo /usr/local/bin/rke2-uninstall.sh" | ssh "${1}"
            # https://exploit.cz/solved-failed-to-configure-agent-node-password-rejected-duplicate-hostname-or-contents-rke2-k3s/
            echo "/var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml delete secret ${1}.node-password.rke2 -n kube-system" | ssh "${MASTERSRV}"
        fi
    fi

    __COMMANDS__=$(cat <<__EOF__
curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=${RKE2_VERSION} ${IRT:-} \
sudo -E sh -
sudo mkdir -p /etc/rancher/rke2
sudo -E bash -c "printf \"${CONFIGYAML}\" > /etc/rancher/rke2/config.yaml"
sudo systemctl daemon-reload
sudo -E systemctl enable --now rke2-${RKE2ROLE:-server}.service
__EOF__
)
    echo "${__COMMANDS__}" | ssh -tt "$1"
    wait_on_node "$1"
}

# A convenience function called throughout the code to detect node registration
# and wait until ready. The node name needs passed as an argument.
wait_on_node() {
    echo -n "Confirming ${1} registration"
    cat - <<__EOF__ | ssh "${MASTERSRV}" >/dev/null 2>&1
until /var/lib/rancher/rke2/bin/kubectl \
--kubeconfig /etc/rancher/rke2/rke2.yaml get node/${1}
do
    echo -n .
    sleep 2
done
__EOF__
    printf "\nWaiting for %s to become ready\n" "${1}"
    cat - <<__EOF__ | ssh "${MASTERSRV}"
/var/lib/rancher/rke2/bin/kubectl \
--kubeconfig /etc/rancher/rke2/rke2.yaml wait --for=condition=Ready \
node/${1} --timeout=900s
__EOF__
}

# Since this use case may be specific to state stored in this directory, change
# to this directory.
cd "$(dirname "$0")"
# shellcheck disable=SC2064
trap "cd ${OLDPWD}" EXIT

# Install the primary master
CONFIGYAML="token: ${TOKEN}\nwrite-kubeconfig-mode: 644\ntls-san: ${TLSSAN}\nnode-ip: ${NODEIP}.211"
create_rke2_node "${MASTERSRV}"

# Create the URL to add hosts
URL="https://${NODEIP}.211:9345"

# Create additional masters
for ((i=2; i<=MASTER_NODE_COUNT; i++))
do
    CONFIGYAML="server: ${URL}\ntoken: ${TOKEN}\nwrite-kubeconfig-mode: 644\ntls-san: ${TLSSAN}\nnode-ip: ${NODEIP}.$((210+i))"
    create_rke2_node "${MASTERSRV}${i}"
done

# Create each node
IRT='INSTALL_RKE2_TYPE="agent"'
RKE2ROLE="agent"

for ((i=1; i<=AGENT_NODE_COUNT; i++))
do
    CONFIGYAML="server: ${URL}\ntoken: ${TOKEN}\nnode-ip: ${NODEIP}.$((220+i))"
    create_rke2_node "node${i}"
done
