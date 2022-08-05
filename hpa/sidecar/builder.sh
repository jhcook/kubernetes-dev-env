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
#

set -o errexit nounset

# shellcheck source=/dev/null
. env.sh

# Check availability of the required Docker images. If not available, build and
# push to the local registry. If the registry is not available, exit on error.
NIMAGES=(localhost:"${DOCKER_REG_PORT}"/boutique/conntrack-network-init \
         localhost:"${DOCKER_REG_PORT}"/boutique/tcp-exporter)
declare -a FIMAGES

while IFS='' read -r line 
do 
  FIMAGES+=("${line}")
done < <(docker images | grep localhost:"${DOCKER_REG_PORT}"/boutique | awk '{print$1}')

for image in "${NIMAGES[@]}"
do
  if ! printf '%s' "${FIMAGES[@]}" | grep "${image}" &>/dev/null
  then
    printf "image: %s not found\n" "${image##*/}"
    cd "./hpa/sidecar/${image##*/}" || exit
    docker build -t "${image}" .
    docker push "${image}"
    cd "${OLDPWD}" || exit
  else
    printf "image: %s found\n" "${image##*/}"
  fi
done
