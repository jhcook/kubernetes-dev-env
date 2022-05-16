#!/usr/bin/env sh
set -o xtrace
iptables -A INPUT -m conntrack --ctstate ESTABLISHED