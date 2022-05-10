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
# Configure Colima instance to workaround issues like x509 certificate
# verification.
#
# Author: Justin Cook

echo "Reconfiguring Docker daemon.json"
read -r -d '' INSECURE_REGISTRIES <<EOF
{
    "insecure-registries" : [
        "gcr.io",
        "k8s.gcr.io",
    ],
    "features": {
        "buildkit": true
    },
    "exec-opts": [
        "native.cgroupdriver=cgroupfs"
    ]
}
EOF

printf "%s" "${INSECURE_REGISTRIES}" | colima ssh -- sudo bash -c \
  "cat - > /etc/docker/daemon.json && sudo /etc/init.d/docker restart"

echo "Wait for Kind to regain conscience"
sleep 60
