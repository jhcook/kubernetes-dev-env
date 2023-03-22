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
# Install Postee operator in the postee namespace and configure.
#
# Author: Justin Cook

set -o errexit

# shellcheck source=/dev/null
. env.sh

# Add the helm repo
helm repo add aquasecurity https://aquasecurity.github.io/helm-charts/
helm repo update

# Install the chart from the Aqua chart repository
helm upgrade --install postee aquasecurity/postee \
  --namespace postee --create-namespace

# Wait for Trivy to become available
kubectl rollout status statefulsets/postee -n postee
kubectl rollout status deployment/posteeui -n postee