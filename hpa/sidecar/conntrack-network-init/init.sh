#!/usr/bin/env sh
set -o xtrace

iptables -A INPUT -m conntrack --ctstate ESTABLISHED
#nft add rule ip filter INPUT ct state established
