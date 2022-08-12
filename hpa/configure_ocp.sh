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
# Configure OpenShift for use with HPA
#
# Author: Justin Cook

set -o errexit nounset

# shellcheck source=/dev/null
. env.sh

# Iterate through the `hpa/sidecar` subdirectories which should be container
# builds using Dockerfile. In each of these directories, set the path as the
# context for a BuildConfig and create an ImageStream Kubernetes resources are
# able to lookup the image. Kick off a build and follow for each container.

for i in hpa/sidecar/*
do
  if [ -d "${i}" ]
  then
    # Create the ImageStream
    kubectl apply -f - << __EOF__
kind: ImageStream
apiVersion: image.openshift.io/v1
metadata:
  annotations:
    openshift.io/display-name: $(basename "${i}")
  name: $(basename "${i}")
  namespace: "${PROJECT_NAMESPACE}"
spec:
  lookupPolicy:
    local: true
__EOF__

    # Create the BuildConfig
    kubectl apply -f - << __EOF__
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: $(basename "${i}")-image
  labels:
    app: $(basename "${i}")-image
spec:
  source:
    type: Git
    git:
      uri: "https://github.com/jhcook/kubernetes-dev-env.git"
      ref: "devel"
    contextDir: hpa/sidecar/$(basename "${i}")
  strategy:
    type: Docker
    dockerStrategy:
      dockerfilePath: Dockerfile
  output:
    to:
      kind: ImageStreamTag
      name: $(basename "${i}"):latest
__EOF__

    # Set the ImageStream discoverable
    #shellcheck disable=SC2086
    oc set image-lookup "$(basename ${i})"

    # Start the build
    #shellcheck disable=SC2086
    oc start-build "$(basename ${i})-image" -F
  fi
done

oc set image-lookup imagestream --list
