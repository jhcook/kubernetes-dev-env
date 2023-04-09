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
# Setup OpenShift Local
#
# Requires: OpenShift Local installed and CRC running
#
# References:
#  * https://discussion.fedoraproject.org/t/recommended-way-of-adding-ca-certificates/15974/4
#  * https://docs.openshift.com/container-platform/4.11/networking/configuring-a-custom-pki.html
#
# Author: Justin Cook

set -o errexit nounset

# shellcheck source=/dev/null
. env.sh

# The PID placed in the background
WPID=0

cleanup() {
  kill -9 ${WPID} 2> >(printer) > >(printer)
}
trap cleanup INT EXIT

# Setup crc
crc setup
crc config set cpus 8
crc config set memory 30208
crc config set disk-size 100
crc config set enable-cluster-monitoring true
crc config set kubeadmin-password kubeadmin
crc config set pull-secret-file "$(pwd)/private/pull-secret.txt"
crc config set nameserver "$(awk '/^nameserver\ /{print$2}' /etc/resolv.conf)"

# If using a proxy, ensure to configure CRC appropriately. 
if [ -n "${http_proxy-}" ]
then
  crc config set http-proxy "${http_proxy}"
fi

if [ -n "${https_proxy-}" ]
then
  crc config set https-proxy "${https_proxy}"
fi

if [ -n "${no_proxy-}" ]
then
  crc config set no-proxy "${no_proxy}"
fi

# If the proxy is filtering TLS, we need to insert the CA
if [ -f "$(pwd)/private/cert.pem" ]
then
  crc config set proxy-ca-file "$(pwd)/private/cert.pem"
fi

# Configure the pull-secret-file
if [ -f "$(pwd)/private/pull-secret.txt" ]
then
  crc config set pull-secret-file "$(pwd)/private/pull-secret.txt"
fi

SSH_COM="$(paste -s -d ' ' - << __EOF__
ssh
-i ~/.crc/machines/crc/id_ecdsa
-o StrictHostKeyChecking=no
-o IdentitiesOnly=yes
-o ConnectTimeout=3
-p 2222
core@\$(crc ip)
__EOF__
)"

# tl;dr: crc start is a long running process. So start in the background,
# do some hack configuration that should be completely unnecessry, and wait.

nohup crc start --log-level=debug >ocp/debug.log 2>&1 &
WPID=$!

# If cert.cer exists, then add it as a root ca on the host.
# Check to see if the machine's key is available
echo "Waiting for ${HOME}/.crc/machines/crc/id_ecdsa"
until [ -f "${HOME}/.crc/machines/crc/id_ecdsa" ]
do
  sleep 2
done

SSHCMD="$(eval echo "${SSH_COM}")"

# Check if we can successfully connect
echo "Checking connection to machine"
until ${SSHCMD} "whoami" 2> >(printer) > >(printer)
do
  sleep 2
done

# Check if already exists on the machine
echo "Looking for cert.cer on machine"
if ${SSHCMD} "sudo ls /etc/pki/ca-trust/source/anchors/devca.cer" \
2> >(printer) > >(printer)
then
  echo "Found cert.cer on machine"
else
  # Copy cert.cer to the machine and restart update-ca-trust service
  echo "Copying cert.cer to machine"
  if < "$(pwd)/private/cert.cer" ${SSHCMD} "$(cat - << __EOF__
sudo bash -c "cat - >/etc/pki/ca-trust/source/anchors/devca.cer"
sudo systemctl restart coreos-update-ca-trust.service
#sudo systemctl restart crio
#sudo systemctl restart kubelet
__EOF__
  )" 2> >(printer) > >(printer)
  then
    printer "cert.cer added to bundle\n"
  fi
fi

# Wait on `crc start` to complete
echo "Waiting for crc to finish start"
wait ${WPID}

#shellcheck disable=SC2046
eval $(crc oc-env)

# Login to OpenShift
oc login -u kubeadmin -p kubeadmin --insecure-skip-tls-verify=true \
https://api.crc.testing:6443

# Enable cluster monitoring of user namespaces
kubectl apply -f ocp/cluster-monitoring-config.yaml
