#!/usr/bin/env bash
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
