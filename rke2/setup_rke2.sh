#!/usr/bin/env bash
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
# Setup rke2 with multipass for use within this code base.
#
# Requires: multipass
#           jq
#
# Author(s): Sebastiaan van Steenis
#            Justin Cook

# shellcheck source=/dev/null
source env.sh
source "$(dirname "$0")/localenv.sh"

set -o errexit nounset

if [ -z "${TOKEN}" ]
then
    TOKEN=$(echo $RANDOM | md5sum | head -c20)
    echo "Generated agent token: ${TOKEN}"
    sed "s/TOKEN=\".*\"/TOKEN=\"${TOKEN}\"/" "$(dirname "$0")/localenv.sh" > \
        "$(dirname "$0")/localenv.sh.$$"
    mv "$(dirname "$0")/localenv.sh.$$" "$(dirname "$0")/localenv.sh"
fi

# Check if name is given or create random name
if [ -z "${NAME}" ]
then
    NAME=$(grep -E '^[a-z]{5}$' /usr/share/dict/words | shuf -n1)
    echo "Selected name: ${NAME}"
    sed "s/NAME=\".*\"/NAME=\"${NAME}\"/" "$(dirname "$0")/localenv.sh" > \
        "$(dirname "$0")/localenv.sh.$$"
    mv "$(dirname "$0")/localenv.sh.$$" "$(dirname "$0")/localenv.sh"
fi

cleanup() {
    for file in ${SUBDIR:-./}${NAME}-{pm,master,agent}-cloud-init.yaml \
                "$(dirname "$0")/localenv.sh.$$"
    do
        rm -f "${file}" >/dev/null 2>&1
    done
}
trap cleanup EXIT

# Prepare cloud-init template
# Requires: INSTALL_RKE2_TYPE set which defaults to empty string
#           CONFIGYAML set which is a string of YAML
#           RKE2ROLE set which defaults to "server"
create_cloudinit_template() {
    CLOUDINIT_TEMPLATE=$(cat - << EOM
#cloud-config

runcmd:
 - '\curl -sfL https://get.rke2.io | ${CLOUD_INIT_INSTALL} ${IRT:-} sh -'
 - '\mkdir -p /etc/rancher/rke2'
 - '\echo "${CONFIGYAML}" > /etc/rancher/rke2/config.yaml'
 - '\systemctl daemon-reload'
 - '\systemctl enable --now rke2-${RKE2ROLE:-server}'
EOM
)
}

# A convenience function called throughout the code to check the status of an
# instance passed to this function as "$1". If the instance is "Running", then
# carry on silently, "Stopped" then start, and if nonexistent, create a
# multipass instance. Wait on each node to register and become ready.
# It requires arguments passed:
# 1: instance name
# 2: number of cpus
# 3: disk size
# 4: memory size
# 5: image name
# 6: cloud-init file name
create_multipass_node() {
    local __state__
    __state__="$(${MULTIPASSCMD} list --format=json | \
    jq -r ".list[] | select(.name | contains(\"${1}\")) | .state")"
    if [ "${__state__}" = "Running" ]
    then
        :
    elif [ "${__state__}" = "Stopped" ]
    then
        ${MULTIPASSCMD} start "${1}"
    else
        echo "Creating ${1} node"
        ${MULTIPASSCMD} launch --cpus "${2}" --disk "${3}" --memory "${4}" "${5}" \
        --name "${1}" --cloud-init "${SUBDIR:-./}${6}" --timeout=600
    fi
    wait_on_node "${1}"

}

# A convenience function called throughout the code to detect node registration
# and wait until ready. The node name needs passed.
wait_on_node() {
    echo "Confirming ${1} registration"
    ${MULTIPASSCMD} exec "${NAME}-rke2-master-1" -- bash -c "$(cat - <<__EOF__
until /var/lib/rancher/rke2/bin/kubectl \
--kubeconfig /etc/rancher/rke2/rke2.yaml get "node/${1}"
do
    sleep 2
done
__EOF__
)"
    echo "Waiting for ${1} to become ready"
    ${MULTIPASSCMD} exec "${NAME}-rke2-master-1" -- /bin/bash -c "$(cat - <<__EOF__
/var/lib/rancher/rke2/bin/kubectl \
--kubeconfig /etc/rancher/rke2/rke2.yaml wait --for=condition=Ready \
"node/${1}" --timeout=600s
__EOF__
)"
}

cat << __EOF__
Creating cluster ${NAME} with ${MASTER_NODE_COUNT} masters and \
${AGENT_NODE_COUNT} nodes.
__EOF__

# Server specific cloud-init
CONFIGYAML="token: ${TOKEN}\nwrite-kubeconfig-mode: 644\ntls-san: ${TLSSAN}"
create_cloudinit_template
echo "${CLOUDINIT_TEMPLATE}" > "${NAME}-pm-cloud-init.yaml"
create_multipass_node "${NAME}-rke2-master-1" "${MASTER_NODE_CPU}" \
    "${MASTER_DISK_SIZE}" "${MASTER_MEMORY_SIZE}" "${IMAGE}" \
    "${NAME}-pm-cloud-init.yaml"

# Retrieve info to join agent to cluster
SERVER_IP=$($MULTIPASSCMD info "${NAME}-rke2-master-1" --format=json | \
            jq -r ".info.\"${NAME}-rke2-master-1\".ipv4[0]")
URL="https://${SERVER_IP}:9345"

# Create additional masters
CONFIGYAML="server: ${URL}\ntoken: ${TOKEN}\nwrite-kubeconfig-mode: 644\ntls-san: ${TLSSAN}"
create_cloudinit_template
echo "${CLOUDINIT_TEMPLATE}" > "${NAME}-master-cloud-init.yaml"
for ((i=2; i<=MASTER_NODE_COUNT; i++))
do
    create_multipass_node "${NAME}-rke2-master-${i}" "${MASTER_NODE_CPU}" \
        "${MASTER_DISK_SIZE}" "${MASTER_MEMORY_SIZE}" "${IMAGE}" \
        "${NAME}-master-cloud-init.yaml"
done

# Prepare agent node cloud-init
CONFIGYAML="server: ${URL}\ntoken: ${TOKEN}"
IRT='INSTALL_RKE2_TYPE="agent"'
RKE2ROLE="agent"
create_cloudinit_template
echo "${CLOUDINIT_TEMPLATE}" > "${NAME}-agent-cloud-init.yaml"
for ((i=1; i<=AGENT_NODE_COUNT; i++))
do
    create_multipass_node "${NAME}-rke2-agent-${i}" "${AGENT_NODE_CPU}" \
        "${AGENT_DISK_SIZE}" "${AGENT_MEMORY_SIZE}" "${IMAGE}" \
        "${NAME}-agent-cloud-init.yaml"
done

# Check if `kubectl` exists in PATH. If so, merge KUBECONFIG and set as
# default context.
if command -v kubectl
then
    # Retrieve the kubeconfig, edit server address, and merge it with the local
    # kubeconfig in order to use contexts.
    if [ ! -d "$(dirname "${LOCALKUBECONFIG}")" ]
    then
        mkdir "$(dirname "${LOCALKUBECONFIG}")"
    fi
    ${MULTIPASSCMD} copy-files "${NAME}-rke2-master-1:/etc/rancher/rke2/rke2.yaml" - | \
    sed "/^[[:space:]]*server:/ s_:.*_: \"https://${SERVER_IP}:6443\"_" > \
        "${LOCALKUBECONFIG}"
    chmod 0600 "${LOCALKUBECONFIG}"

    "${KUBECTLCMD}" config delete-context "${NAME}-rke2-cluster" || /usr/bin/true
    export KUBECONFIG="${KUBECONFIG:-${HOME}/.kube/config}:${LOCALKUBECONFIG}"
    if [ ! -d "$(dirname "${KUBECONFIG%%:*}")" ]
    then
        mkdir "$(dirname "${KUBECONFIG%%:*}")"
    fi
    "${KUBECTLCMD}" config view --flatten > "${KUBECONFIG%%:*}"
    "${KUBECTLCMD}" config set-context "${NAME}-rke2-cluster" --namespace default
else
    cat << __EOF__

kubectl not found in PATH
Use the following alias for kubectl:
alias kubectl="\${MULTIPASSCMD} exec \${NAME}-rke2-master-1 -- \
/var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml"

__EOF__
fi

echo "rke2 setup complete"
${KUBECTLCMD} get nodes

echo "Please configure ${TLSSAN} to resolve to ${SERVER_IP}"
