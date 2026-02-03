#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

CHAMELEOND_DIR="/etc/chromiumos/src/platform/chameleon"
CHAMELEOND_VENV="${CHAMELEOND_DIR}/venv"
BTSOCKET_DIR="/etc/chromiumos/src/platform/btsocket"

echo "Creating chameleond venv at '${CHAMELEOND_VENV}'"
python3 -m venv "${CHAMELEOND_VENV}" --system-site-packages

echo "Entering chameleond venv"
source "${CHAMELEOND_VENV}/bin/activate"

echo "Installed Python runtime:"
python3 --version
python3 -m pip --version

echo "Installing chameleond python dependencies..."
python3 -m pip install -r "${CHAMELEOND_DIR}/requirements.txt"

echo "Removing ChromeOS btsocket python source from rootfs..."
rm -r "${BTSOCKET_DIR}"

echo "Successfully created venv for chameleond at '${CHAMELEOND_VENV}'"

# Link chameleond python source root for run script.
ln -s "${CHAMELEOND_DIR}/chameleond" "${CHAMELEOND_DIR}/utils/chameleond"

echo "Add chameleond and bluetooth grpc as service"
# Generate systemd service from init.d service.
update-rc.d chameleond defaults 92 8
update-rc.d bluetooth_grpc defaults 100 6

# Enable generated systemd service.
systemctl enable chameleond.service
systemctl stop bluetooth_grpc.service
systemctl disable bluetooth_grpc.service

# Add packages from chameleond/bin to usr/bin
cp -a "${CHAMELEOND_DIR}"/bin/. /usr/bin/

# Setup Bluetooth GRPC service for chameleond
PANDORA_STABLE_VERSION="0.0.6"
PANDORA_EXPERIMENTAL_VERSION="0.0.0"
BLUESHIP_VERSION="0.0.0"

BLUETOOTH_GRPC_ROOT_DIR="${CHAMELEOND_DIR}/chameleond/tmp/bluetooth_grpc"
PANDORA_DIR="${BLUETOOTH_GRPC_ROOT_DIR}/bt-test-interfaces-${PANDORA_STABLE_VERSION}"
PANDORA_EXPERIMENTAL_DIR="${BLUETOOTH_GRPC_ROOT_DIR}/pandora-experimental-${PANDORA_EXPERIMENTAL_VERSION}"
BLUESHIP_DIR="${BLUETOOTH_GRPC_ROOT_DIR}/blueship-${BLUESHIP_VERSION}"

python3 -m grpc_tools.protoc \
          -I"${PANDORA_DIR}" -I"${PANDORA_EXPERIMENTAL_DIR}" -I"${BLUESHIP_DIR}"\
          --plugin=protoc-gen-grpc="${BLUETOOTH_GRPC_ROOT_DIR}"/protoc-gen-custom_grpc \
          --python_out="${BLUETOOTH_GRPC_ROOT_DIR}"/python \
          --grpc_out="${BLUETOOTH_GRPC_ROOT_DIR}"/python \
          "${PANDORA_DIR}"/pandora/* \
          "${PANDORA_EXPERIMENTAL_DIR}"/pandora_experimental/* \
          "${BLUESHIP_DIR}"/blueship/*

python3 -m pip install --upgrade "${BLUETOOTH_GRPC_ROOT_DIR}"
cd "${CHAMELEOND_DIR}"
# add --cyclone5 to ignore installation of cryptography(2.6.1 is too old for Python3.11), will be removed after setup.py changed
python3 setup.py install -f --grpc --cyclone5 --install-scripts="${CHAMELEOND_DIR}"
