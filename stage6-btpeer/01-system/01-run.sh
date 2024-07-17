#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

echo "Copying sub-stage 01-system files to rootfs"
rsync -a rootfs/* "${ROOTFS_DIR}"
chmod 644 "${ROOTFS_DIR}/boot/firmware/config.txt"

# Start building the build info JSON file.
# The data format is defined as RaspiosCrosBtpeerImageBuildInfo in the proto
# chromiumos/src/config/proto/chromiumos/test/lab/api/bluetooth_peer.proto.
echo "Initializing build info"
IMAGE_UUID=$(uuidgen)
IMAGE_TIMESTAMP=$(date --utc +%FT%T.%NZ)
BUILD_INFO_JSON='{}'
BUILD_INFO_JSON=$(jq '."image_uuid" = $val' --arg val "${IMAGE_UUID}" <<< "${BUILD_INFO_JSON}")
BUILD_INFO_JSON=$(jq '."image_build_time" = $val' --arg val "${IMAGE_TIMESTAMP}" <<< "${BUILD_INFO_JSON}")
BUILD_INFO_JSON=$(jq '."sources"."https://chromium.googlesource.com/chromiumos/third_party/pi-gen-btpeer" = $val' --arg val "${PI_GEN_COMMIT}" <<< "${BUILD_INFO_JSON}")
mkdir -p $(dirname "${ROOTFS_DIR}/${BUILD_INFO_FILE_PATH}")
echo "${BUILD_INFO_JSON}" > "${ROOTFS_DIR}/${BUILD_INFO_FILE_PATH}"
echo -e "Current Build info:\n${BUILD_INFO_JSON}"

# Build ssh banner with system details:
ROOTFS_SSH_BANNER_FILE="${ROOTFS_DIR}/etc/btpeer/ssh_banner.txt"
mkdir -p "$(dirname "${ROOTFS_SSH_BANNER_FILE}")"
echo "
------------------------------------------------------------
ChromeOS Test Btpeer
 * Device: Raspberry Pi
 * ImageUUID: ${IMAGE_UUID}
------------------------------------------------------------
" > "${ROOTFS_SSH_BANNER_FILE}"

# Copy testing_rsa public key from ChromeOS to rootfs to allow root login via SSH.
CHROMIUMOS_TESTING_RSA_PUB_KEY_PATH="${CHROMIUMOS_DOCKER_DIR}/src/third_party/chromiumos-overlay/chromeos-base/chromeos-ssh-testkeys/files/testing_rsa.pub"
mkdir -p "${ROOTFS_DIR}/root/.ssh"
cp "${CHROMIUMOS_TESTING_RSA_PUB_KEY_PATH}" "${ROOTFS_DIR}/root/.ssh/authorized_keys"

# Copy testing_rsa private key from ChromeOS to rootfs to allow scp to DUT.
CHROMIUMOS_TESTING_RSA_PRI_KEY_PATH="${CHROMIUMOS_DOCKER_DIR}/src/third_party/chromiumos-overlay/chromeos-base/chromeos-ssh-testkeys/files/testing_rsa"
mkdir -p "${ROOTFS_DIR}/root/.ssh"
cp "${CHROMIUMOS_TESTING_RSA_PRI_KEY_PATH}" "${ROOTFS_DIR}/root/.ssh/"

# Create .config directory with the expected permissions/ownership if it doesn't already exist.
install -v -o 1000 -g 1000 -d "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config"
