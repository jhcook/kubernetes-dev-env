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
# Requires: limactl

set -o errexit

# shellcheck source=/dev/null
. env.sh

# Start limactl default
limactl start default

if ! curl --connect-timeout 3 http://$(minikube ip):5000/v2/_catalog &>/dev/null
then
  # Start the docker registry and for to Minikube
  lima nerdctl run --rm -it --network=host alpine ash -c \
  "apk add socat && socat TCP-LISTEN:5000,reuseaddr,fork TCP:$(minikube ip):5000" &
fi

num_try=0
while [ $num_try -le 20 ]
do
  if ! curl --connect-timeout 3 http://$(minikube ip):5000/v2/_catalog &>/dev/null
  then
    num_try=$((num_try+1))
    sleep 5
  else
    break
  fi
done

# Check availability of the required Docker images. If not available, build and
# push to the local registry. If the registry is not available, exit on error.
NIMAGES=(localhost:5000/jhcook/conntrack-network-init \
         localhost:5000/jhcook/tcp-exporter)
declare -a FIMAGES

while IFS='' read -r line 
do 
  FIMAGES+=("${line}")
done < <(lima nerdctl images | grep localhost:5000/jhcook | awk '{print$1}')

for image in "${NIMAGES[@]}"
do
  if ! printf '%s' "${FIMAGES[@]}" | grep "${image}" &>/dev/null
  then
    cd "./hpa/sidecar/${image##*/}" || exit
    lima nerdctl build -t "${image}" .
    lima nerdctl push "${image}"
    cd "${OLDPWD}" || exit
  fi
done