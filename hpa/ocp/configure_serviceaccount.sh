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
# Configure deployments to use service account
#
# References:
# * https://www.nginx.com/blog/microservices-march-reduce-kubernetes-latency-with-autoscaling/
# * https://stackoverflow.com/questions/62578789/kubectl-patch-is-it-possible-to-add-multiple-values-to-an-array-within-a-sinlge
#
# Requires: oc
#
# Author: Justin Cook

set -o errexit nounset

# shellcheck source=/dev/null
. env.sh

# Patch each deployment with appropriate service account
for deploy in $(kubectl get deploy -n "${PROJECT_NAMESPACE}" -o name | \
                grep -E 'service$')
do
  # Configure the deployment to use service account
  oc patch "${deploy}" -n "${PROJECT_NAMESPACE}" -p \
    '{"spec": {"template": {"spec": {"serviceAccountName": "net-dac-cap-anyuid"}}}}'
done