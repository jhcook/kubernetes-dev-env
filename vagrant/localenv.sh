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
# Setup RKE2 environment

# shellcheck disable=SC2034

#set -x

# Set an alias for ssh to vagrant ssh
alias ssh="vagrant ssh"

# Set the amount of master nodes to create
MASTER_NODE_COUNT=1

# Set the amount of worker nodes to create
AGENT_NODE_COUNT=3

# Information that is necessary to deploy RKE2 is as follows:
# * MASTERSRV
#   The primary master node name that resolves as configured by
#   nsswitch on each node.
# * RKE2_VERSION
#   This is the specific RKE2 release to deploy on each node.
# * NODEIP
#   The first three octets of the IP addresses used
# * TLSSAN 
#   A list of subject alternative names (hostnames or IPv4/IPv6 addrs)
#   on the server's TLS cert.
# * TOKEN a preshared secret used to join a server or agent to a cluster
#   use echo `$RANDOM | md5sum | head -c32` to generate a random token

MASTERSRV="master"
RKE2_VERSION="v1.24.12+rke2r1"
#RKE2_VERSION="v1.25.8+rke2r1"
NODEIP="192.168.123"
TLSSAN="rancher.test"
TOKEN="01010101010101010101010101010101"
