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
# Delete cert-manager
#
# https://cert-manager.io/v1.2-docs/installation/uninstall/kubernetes/

# Ensure that all cert-manager resources that have been created have been
# deleted.
RESOURCES="Issuers,ClusterIssuers,Certificates,CertificateRequests,Orders,Challenges"
for obj in $(kubectl get ${RESOURCES} --all-namespaces)
do
    kubectl delete "${obj}"
done

# Delete cert-manager
helm --namespace cert-manager delete cert-manager

# Delete the namespace
kubectl delete ns cert-manager --wait=0

# Delete the CRDs
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.10.2/cert-manager.crds.yaml
