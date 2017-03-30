#!/bin/bash

# Copyright 2016 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# A library of helper functions and constant for the Container Linux distro.
source "${KUBE_ROOT}/cluster/gce/container-linux/helper.sh"

function write-gpu-kit {
    if [ ! -f ${KUBE_TEMP}/gpu-kit.tar.gz ]; then
        export GPU_KIT_TAR=${KUBE_ROOT}/server/gpu-kit.tar.gz
        tar -C $(dirname "${BASH_SOURCE[0]}")/gpu-kit -cz . > ${GPU_KIT_TAR}
    fi
}

function get-node-instance-template-args {
    if [ "${GPU_COUNT}" -gt "0" ]; then
        echo "kube-env=${KUBE_TEMP}/node-kube-env.yaml" \
             "user-data=${KUBE_ROOT}/cluster/gce/container-linux/node-gpu.yaml" \
             "configure-sh=${KUBE_ROOT}/cluster/gce/container-linux/configure.sh" \
             "cluster-name=${KUBE_TEMP}/cluster-name.txt"
    else
        echo "kube-env=${KUBE_TEMP}/node-kube-env.yaml" \
             "user-data=${KUBE_ROOT}/cluster/gce/container-linux/node.yaml" \
             "configure-sh=${KUBE_ROOT}/cluster/gce/container-linux/configure.sh" \
             "cluster-name=${KUBE_TEMP}/cluster-name.txt"
    fi
}

# $1: template name (required).
function create-node-instance-template {
  local template_name="$1"

  create-node-template "$template_name" "${scope_flags[*]}" $(get-node-instance-template-args)
  # TODO(euank): We should include update-strategy here. We should also switch to ignition
}
