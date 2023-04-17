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
# Merge KUBECONFIG from Vagrant RKE2 master to platform KUBECONFIG and create
# a default context.

set -o errexit nounset
shopt -s expand_aliases

# shellcheck source=/dev/null
. env.sh
. "$(dirname "$0")/localenv.sh"

# Fetch to KUBECONFIG from the master, change the server address, merge with
# the host's KUBECONFIG, and set context.
if [ ! -d "${HOME}/.kube" ]
then
    mkdir "${HOME}/.kube"
fi

cd vagrant
# shellcheck disable=SC2064
trap "cd ${OLDPWD}" EXIT

echo "Fetching kubeconfig from master"
echo "cat /etc/rancher/rke2/rke2.yaml" | ssh master | \
  sed -E "s|(server: https://)[0-9.]+:([0-9]+)|\1${SRVRIP}:\2|g" | \
  cat - > "${HOME}/.kube/config-vagrant"

echo "Merging and creating context as default for the cluster"
kubectl config delete-context vagrant-cluster || /usr/bin/true
chmod 0600 "${HOME}/.kube/config-vagrant"
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}:${HOME}/.kube/config-vagrant"
kubectl config view --flatten > "${KUBECONFIG%%:*}"
kubectl config set-context vagrant-cluster --namespace default
