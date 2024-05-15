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

# Generate systemd service from init.d service.
update-rc.d chameleond defaults 92 8

# Enable generated systemd service.
systemctl enable chameleond.service

# Add legacy package path support by linking packages now in /usr/ to /usr/local/
USR_PACKAGES_TO_LINK_LOCAL=(
  sbin/i2cdump
  sbin/i2cget
  sbin/i2cset
  bin/pacat
  bin/pactl
  bin/pulseaudio
)
for PKG in ${USR_PACKAGES_TO_LINK_LOCAL[@]}; do
  TARGET_PATH="/usr/${PKG}"
  LINK_PATH="/usr/local/${PKG}"
  echo "Linking '${LINK_PATH}' to '${TARGET_PATH}'"
  if [ ! -L "${LINK_PATH}" ]; then
      ln -s "${TARGET_PATH}" "${LINK_PATH}"
  fi
done

USR_PACKAGES_TO_LINK=(
  modprobe
)

for PKG in ${USR_PACKAGES_TO_LINK[@]}; do
  TARGET_PATH="/usr/sbin/${PKG}"
  LINK_PATH="/usr/bin/${PKG}"
  echo "Linking '${LINK_PATH}' to '${TARGET_PATH}'"
  if [ ! -L "${LINK_PATH}" ]; then
      ln -s "${TARGET_PATH}" "${LINK_PATH}"
  fi
done
