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
# Setup Rancher Desktop for use within this code base.
#
# Author: Justin Cook

PATH="${HOME}/.rd/bin:${PATH}"
echo "Starting Rancher Desktop"

rdctl start --kubernetes.enabled=true \
            --kubernetes.options.flannel=false \
            --kubernetes.options.traefik=false \
            --kubernetes.version=v1.24.12 \
            --container-engine.name=containerd \
            --virtual-machine.memory-in-gb=32 \
            --virtual-machine.number-cpus=4 \
            --application.admin-access=true \
            --application.telemetry.enabled=false

echo -n "Waiting on API."

until kubectl get nodes >/dev/null 2>&1
do
    sleep 1
    echo -n '.'
done
echo

kubectl config set-context rancher-desktop
