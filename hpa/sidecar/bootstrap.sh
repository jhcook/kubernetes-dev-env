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

# Start lima_default. For some reason if name is already running it exits
# nonzero ....
if [ "$(limactl ls lima_default -f '{{.Status}}')" == "Stopped" ]
then
  limactl start lima_default
elif [ "$(limactl ls lima_default -f '{{.Status}}')" == "Running" ]
then
  :
else
  limactl start --tty=false ./kind/lima_default.yaml
fi

export LIMA_INSTANCE="lima_default"
docker context create lima-docker --docker \
  "host=unix://$HOME/.lima/docker/sock/docker.sock" || /usr/bin/true
docker context use lima-docker || /usr/bin/true
export DOCKER_HOST="tcp://localhost:2375"

if ! curl --connect-timeout 3 http://localhost:"${DOCKER_REG_PORT}"/v2/_catalog &>/dev/null
then
  # Forward port to the docker registry on Minikube
  printf "registry: localhost: not found: forwarding\n"
  docker run -d --network=host alpine ash -c \
  "apk add socat && socat TCP-LISTEN:${DOCKER_REG_PORT},reuseaddr,fork TCP:$(minikube ip):5000"
fi

num_try=0
while [ $num_try -le 20 ]
do
  if ! curl --connect-timeout 3 http://localhost:"${DOCKER_REG_PORT}"/v2/_catalog &>/dev/null
  then
    printf "registry: waiting on localhost:%s\n" "${DOCKER_REG_PORT}"
    num_try=$((num_try+1))
    sleep 5
  else
    printf "registry: localhost:%s} found\n" "${DOCKER_REG_PORT}"
    break
  fi
done
