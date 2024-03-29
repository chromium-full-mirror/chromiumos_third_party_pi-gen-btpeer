#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

echo "Copying sub-stage 01-system files to rootfs"
rsync -a rootfs/* "${ROOTFS_DIR}"

# Build ssh banner with system details:
ROOTFS_SSH_BANNER_FILE="${ROOTFS_DIR}/etc/btpeer/ssh_banner.txt"
mkdir -p "$(dirname "${ROOTFS_SSH_BANNER_FILE}")"
echo "
------------------------------------------------------------
ChromeOS Test Btpeer
 * Device: Raspberry Pi
------------------------------------------------------------
" > "${ROOTFS_SSH_BANNER_FILE}"

# Copy testing_rsa public key from ChromeOS to rootfs to allow root login via SSH.
CHROMIUMOS_TESTING_RSA_PUB_KEY_PATH="${CHROMIUMOS_DOCKER_DIR}/src/third_party/chromiumos-overlay/chromeos-base/chromeos-ssh-testkeys/files/testing_rsa.pub"
mkdir -p "${ROOTFS_DIR}/root/.ssh"
cp "${CHROMIUMOS_TESTING_RSA_PUB_KEY_PATH}" "${ROOTFS_DIR}/root/.ssh/authorized_keys"

# Set default root password to standard test password (not allowed in SSH, just for local access).
on_chroot << EOF
echo "root:test0000" | chpasswd
EOF

# Disable wifi to reduce noise in wificell. We only connect to btpeer over ethernet or bluetooth.
on_chroot << EOF
systemctl disable wpa_supplicant
EOF
