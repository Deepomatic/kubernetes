#!/bin/bash

# Copyright 2016 Deepomatic.
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

set -e

BIN_PATH=/opt/bin
LIB_PATH=/opt/lib64
MOD_PATH=${LIB_PATH}/modules

# Utility fonction to untar a bzip2 to a specific path
function untar_file {
  DIR=$1
  FILE=$2
  mkdir -p ${DIR}
  cd ${DIR}
  tar -xvjf ${FILE}
  rm ${FILE}
}

# Create files
SCRIPT_DIR=$(dirname $0)
mkdir -p /etc/ld.so.conf.d
echo ${LIB_PATH} | tee - > /etc/ld.so.conf.d/nvidia_drivers.conf
mkdir -p /etc/udev/rules.d
cp ${SCRIPT_DIR}/71-nvidia.rules /etc/udev/rules.d/
mkdir -p ${BIN_PATH}
cp ${SCRIPT_DIR}/create-uvm-dev-node.sh ${BIN_PATH}/

# Download drivers
COREOS_VERSION=$(cat /etc/os-release | grep "VERSION=" | cut -f2 -d=)
DRIVERS_ARCHIVE=drivers-${COREOS_VERSION}-${NVIDIA_DRIVER_VERSION}.tar.bz2
set +e
mkdir -p /opt
cd /opt
rm -f ${DRIVERS_ARCHIVE}
wget -q https://s3-eu-west-1.amazonaws.com/deepomatic-resources/nvidia/coreos/${DRIVERS_ARCHIVE}
R=$?
set -e

# Build drivers
if [ "$R" != "0" ]; then
    git clone https://github.com/Deepomatic/coreos-nvidia.git
    cd coreos-nvidia
    sudo ./build.sh ${NVIDIA_DRIVER_VERSION}
    mv ${DRIVERS_ARCHIVE} /opt
    cd /opt
    sudo rm -rf coreos-nvidia
fi

# Unzip drivers
BIN_FILE=/opt/tools-${NVIDIA_DRIVER_VERSION}.tar.bz2
LIB_FILE=/opt/libraries-${NVIDIA_DRIVER_VERSION}.tar.bz2
MOD_FILE=/opt/modules-${COREOS_VERSION}-${NVIDIA_DRIVER_VERSION}.tar.bz2
rm -f $BIN_FILE $LIB_FILE $MOD_FILE
tar -xvjf ${DRIVERS_ARCHIVE}
rm ${DRIVERS_ARCHIVE}

# Copy tools, libraries and modules
untar_file ${BIN_PATH} ${BIN_FILE}
untar_file ${LIB_PATH} ${LIB_FILE}
untar_file ${MOD_PATH} ${MOD_FILE}

# Register new libs
#udevadm control --reload-rules && udevadm trigger
ldconfig

# Create nvidia-persistence user
useradd --system --home '/' --shell '/sbin/nologin' -c 'NVIDIA Persistence Daemon' nvidia-persistenced || echo "Probably already existing"


