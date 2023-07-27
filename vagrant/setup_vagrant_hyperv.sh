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
# Create Vagrant noes in accordance with Vagrantfile

set -o errexit nounset

# shellcheck source=/dev/null
. env.sh

cd "$(pwd)/vagrant"

export VAGRANT_VAGRANTFILE=Vagrantfile.hyperv

# shellcheck disable=SC2064
trap "cd ${OLDPWD}" EXIT

vagrant up

# Now we have running boxes do post configuration as Hyperv is limited
# https://developer.hashicorp.com/vagrant/docs/providers/hyperv/limitations
RUNNING_MACHINES="$(vagrant status | awk '$2 == "running" {print$1}')"

for machine in ${RUNNING_MACHINES}
do
  IP="$(vagrant ssh-config "${machine}" | awk '/HostName/{print$2}')"

  if awk 'BEGIN {rc=1} /__HOSTS__/{f=1;next} f && /__HOSTS__/{exit} f && /[0-9.]+\t'"${machine}"'/{print "found"; rc=0; exit} END {exit rc}' hyperv_hosts.sh
  then
    sed -i -E "s/^[0-9.]+\\s+${machine}$/${IP}\\t${machine}/" hyperv_hosts.sh
  else
    sed -i "/^__HOSTS__$/i\\
${IP}\\t${machine}
" hyperv_hosts.sh
  fi
done

vagrant provision --provision-with hosts
