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
# Setup OpenShift Local
#
# Requires: OpenShift Local installed and CRC running
#
# Author: Justin Cook

set -o errexit nounset

# shellcheck source=/dev/null
. env.sh

crc setup
crc config set cpus 6
crc config set memory 30208
crc config set disk-size 100
crc config set enable-cluster-monitoring true

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

if [ -f "cert.pem" ]
then
  crc config set proxy-ca-file "$(pwd)/cert.pem"
fi

crc start

#shellcheck disable=SC2046
eval $(crc oc-env)

#shellcheck disable=SC2046
eval $(crc console --credentials | grep kubeadmin | awk -F"'" '{print $2}')

# Enable cluster monitoring of user namespaces
kubectl apply -f ocp/cluster-monitoring-config.yaml

# We are recreating the registries config file and restarting associated
# services at the same time we are adding the integrated registry as insecure.
#shellcheck disable=SC2034
SSH_COM=$(paste -s -d ' ' - << __EOF__
ssh
-i ~/.crc/machines/crc/id_ecdsa
-o StrictHostKeyChecking=no
core@$(crc ip)
-p2222
__EOF__
)

#cat << __EOF__ | ${SSH_COM} "sudo bash -c \"cat - > /etc/containers/registries.conf\""
#unqualified-search-registries = ['registry.access.redhat.com', 'docker.io', 'image-registry.openshift-image-registry.svc:5000']
#prefix = ""

#[[registry]]
#  location = "image-registry.openshift-image-registry.svc:5000"
#  insecure = true
#  blocked = false
#  mirror-by-digest-only = false
#  prefix = ""
#__EOF__

#${SSH_COM} "sudo systemctl restart crio"
#${SSH_COM} "sudo systemctl restart kubelet"
