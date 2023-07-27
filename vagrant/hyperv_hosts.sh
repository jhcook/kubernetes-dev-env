#!/usr/bin/env bash
#
# This file is used as a Vagrant provisioner and is intended to be edited
# programmatically for use by Vagrant direct.
#
# Author: Justin Cook

HOSTS_FILE="$(cat << __HOSTS__
172.18.18.42	master
172.18.29.50	node1
172.18.24.130	node2
__HOSTS__
)"

printf "%s" "${HOSTS_FILE}" >> /etc/hosts
