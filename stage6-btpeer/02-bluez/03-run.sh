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
