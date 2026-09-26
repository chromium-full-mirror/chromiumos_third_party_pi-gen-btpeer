#!/bin/bash -e

# Copyright 2026 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Prevent `cros lint` failing check for environment variables
: "${ROOTFS_DIR:?ROOTFS_DIR environment variable must be set}"

# Copied after the bluez package install so the package does not overwrite
# the btpeer bluetooth.service.
if [ -d "rootfs" ]; then
  echo "Copying sub-stage 02-bluez files to rootfs"
  rsync -a rootfs/* "${ROOTFS_DIR}"
  echo "Successfully copied sub-stage 02-bluez files to rootfs"
fi

# Disable EATT by default (Channels = 1) in /etc/bluetooth/main.conf to match
# RPi OS 10 (BlueZ 5.50) single-ATT-bearer behavior and newer upstream BlueZ,
# which reverted the default Channels value from 3 back to 1 (b/566562103).
BLUEZ_MAIN_CONF="${ROOTFS_DIR}/etc/bluetooth/main.conf"
sed -i 's/^#*Channels = .*/Channels = 1/' "${BLUEZ_MAIN_CONF}"
if ! grep -q '^Channels = 1$' "${BLUEZ_MAIN_CONF}"; then
  echo "Failed to set Channels = 1 in ${BLUEZ_MAIN_CONF}"
  exit 1
fi

