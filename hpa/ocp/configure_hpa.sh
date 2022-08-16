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
# Requires: oc
#
# Author: Justin Cook

set -o errexit nounset

# shellcheck source=/dev/null
. env.sh

# Install the OpenShift custom metrics autoscaler
oc create namespace openshift-keda --dry-run=client -o yaml | \
  oc apply -f -
for file in openshift-keda-operator-group openshift-keda-subscription \
            custom-metrics-autoscaler
do
  oc create -f hpa/ocp/${file}.yaml -n openshift-keda --dry-run=client -o yaml | 
    oc apply -f -
done

# Wait for all the deployments to become available
for deploy in $(oc get deploy -n openshift-keda -o name)
do
  oc rollout status "${deploy}" -n openshift-keda
done

oc create -f hpa/ocp/openshift-keda-controller.yaml -n openshift-keda \
  --dry-run=client -o yaml | oc apply -f -

# Wait for kedacontrollers.keda.sh to become available
oc wait --for condition=established --timeout=60s crd/kedacontrollers.keda.sh

# Create a Security Context Constraints (SCC) allowing the appropriate Linux
# capabilities for conntrack-network-init and tcp-exporter containers.

oc apply -f - << __EOF__
apiVersion: security.openshift.io/v1
kind: SecurityContextConstraints
metadata:
  annotations:
    kubernetes.io/description: provides all features of the restricted SCC
      but allows users to run with any UID, any GID, and allows escalated
      network and discretionary access control privileges.
  name: net-dac-cap-anyuid
allowHostDirVolumePlugin: false
allowHostIPC: false
allowHostNetwork: false
allowHostPID: false
allowHostPorts: false
allowPrivilegeEscalation: true
allowPrivilegedContainer: false
allowedCapabilities:
  - NET_BIND_SERVICE
  - NET_ADMIN
  - NET_RAW
  - DAC_READ_SEARCH
  - DAC_OVERRIDE
defaultAddCapabilities: null
fsGroup:
  type: RunAsAny
groups:
- system:authenticated
priority: 10
readOnlyRootFilesystem: false
runAsUser:
  type: RunAsAny
seLinuxContext:
  type: RunAsAny
supplementalGroups:
  type: RunAsAny
users: []
volumes:
- configMap
- downwardAPI
- emptyDir
- persistentVolumeClaim
- projected
- secret
__EOF__

# Create a role allowing the use of the net-dac-cap-restricted SCC, a service
# account, and a role binding the service account to the role. 

oc apply -f - -n "${PROJECT_NAMESPACE}" << __EOF__
apiVersion: v1
kind: ServiceAccount
metadata:
  name: net-dac-cap-anyuid
  namespace: "${PROJECT_NAMESPACE}"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: net-dac-cap-anyuid
  namespace: "${PROJECT_NAMESPACE}"
rules:
- apiGroups:
  - security.openshift.io 
  resourceNames:
  - net-dac-cap-anyuid
  resources:
  - securitycontextconstraints 
  verbs: 
  - use
---
  apiVersion: rbac.authorization.k8s.io/v1
  kind: RoleBinding
  metadata:
    name: net-dac-cap-anyuid
    namespace: "${PROJECT_NAMESPACE}"
  subjects:
  - kind: ServiceAccount
    name: net-dac-cap-anyuid
  roleRef:
    kind: Role
    name: net-dac-cap-anyuid
    apiGroup: rbac.authorization.k8s.io
__EOF__

# Iterate through the `hpa/sidecar` subdirectories which should be container
# builds using Dockerfile. In each of these directories, set the path as the
# context for a BuildConfig and create an ImageStream Kubernetes resources are
# able to lookup the image. Kick off a build and follow for each container.

for i in hpa/sidecar/*
do
  if [ -d "${i}" ]
  then
    # Create the ImageStream
    oc apply -f - << __EOF__
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
    oc apply -f - << __EOF__
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
      dockerfilePath: ocp/Dockerfile
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

# Create an Ingress for the Boutique®
oc apply -f hpa/frontend-ingress.yaml -n "${PROJECT_NAMESPACE}"