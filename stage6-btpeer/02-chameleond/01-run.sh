#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Copy chameleond source to rootfs.
CHAMELEON_SRC_DOCKER_DIR="${CHROMIUMOS_DOCKER_DIR}/src/platform/chameleon"
CHAMELEOND_ROOTFS_DIR="${ROOTFS_DIR}/etc/chromiumos/src/platform/chameleon"
CHAMELEOND_PROJECT_DIST_DIR="${CHAMELEON_SRC_DOCKER_DIR}/dist"
echo "Identifying chameleond bundle"
if [ ! -d "${CHAMELEOND_PROJECT_DIST_DIR}" ]; then
  echo "Error: No chameleond dist directory found at '${CHAMELEOND_PROJECT_DIST_DIR}'; chameleond must be packaged first with PACKAGE_CHAMELEOND=1"
  exit 1
fi
CHAMELEON_COMMIT=$(cat ${CHAMELEOND_PROJECT_DIST_DIR}/commit)
CHAMELEOND_BUNDLE_FILENAME=$(cd "${CHAMELEOND_PROJECT_DIST_DIR}" && find * -maxdepth 1 -type f -iname "chameleond-*.tar.gz")
CHAMELEOND_BUNDLE_PATH="${CHAMELEOND_PROJECT_DIST_DIR}/${CHAMELEOND_BUNDLE_FILENAME}"
if [ ! -f "${CHAMELEOND_BUNDLE_PATH}" ]; then
  echo "Error: No chameleond bundle found in '${CHAMELEOND_PROJECT_DIST_DIR}'"
  exit 1
fi
echo "Using chameleond bundle '${CHAMELEOND_BUNDLE_PATH}'"
if [ -d "${CHAMELEOND_ROOTFS_DIR}" ]; then
  echo "Removing previously extracted chameleond bundle in rootfs"
  rm -rf "${CHAMELEOND_ROOTFS_DIR}"
fi
echo "Extracting chameleond bundle into rootfs"
mkdir -p "${CHAMELEOND_ROOTFS_DIR}"
(cd "${CHAMELEOND_ROOTFS_DIR}" && \
tar -zxf "${CHAMELEOND_BUNDLE_PATH}" --strip-components=1)
echo "Copying chameleond bundle config files to system locations in rootfs"
cp "${CHAMELEOND_ROOTFS_DIR}/chameleond/utils/btkbservice.conf" "${ROOTFS_DIR}/etc/dbus-1/system.d/org.chromium.autotest.btkbservice.conf"
WIREPLUMBER_CONFIG_DIR="${ROOTFS_DIR}/home/pi/.config/bluetooth.lua.d"
mkdir -p "${WIREPLUMBER_CONFIG_DIR}"
cp "${CHAMELEOND_ROOTFS_DIR}/updatable/wireplumber/bluetooth.lua.d/"* "${WIREPLUMBER_CONFIG_DIR}"
echo "Successfully extracted chameleond bundle to rootfs at ${CHAMELEOND_ROOTFS_DIR}"

# Copy btsocket source to rootfs (installed into venv via requirements.txt, then source is deleted).
BTSOCKET_SRC_DOCKER_DIR="${CHROMIUMOS_DOCKER_DIR}/src/platform/btsocket"
git config --global --add safe.directory "${BTSOCKET_SRC_DOCKER_DIR}"
BTSOCKET_COMMIT=$(cd "${BTSOCKET_SRC_DOCKER_DIR}" && git rev-parse --short HEAD)
BTSOCKET_ROOTFS_DIR="${ROOTFS_DIR}/etc/chromiumos/src/platform/btsocket"
echo "Copying ChromeOS btsocket source to rootfs"
mkdir -p "${BTSOCKET_ROOTFS_DIR}"
rsync -a "${BTSOCKET_SRC_DOCKER_DIR}/" "${BTSOCKET_ROOTFS_DIR}/" --exclude .git --exclude .idea
echo "Successfully copied ChromeOS btsocket source to rootfs"

echo "Updating build info"
BUILD_INFO_JSON=$(cat "${ROOTFS_DIR}/${BUILD_INFO_FILE_PATH}")
BUILD_INFO_JSON=$(jq '."sources"."https://chromium.googlesource.com/chromiumos/platform/chameleon" = $val' --arg val "${CHAMELEON_COMMIT}" <<< "${BUILD_INFO_JSON}")
BUILD_INFO_JSON=$(jq '."sources"."https://chromium.googlesource.com/chromiumos/platform/btsocket" = $val' --arg val "${BTSOCKET_COMMIT}" <<< "${BUILD_INFO_JSON}")
echo "${BUILD_INFO_JSON}" > "${ROOTFS_DIR}/${BUILD_INFO_FILE_PATH}"
echo -e "Current Build info:\n${BUILD_INFO_JSON}"

echo "Copying sub-stage 02-chameleond files to rootfs"
rsync -a rootfs/* "${ROOTFS_DIR}"
echo "Successfully copied sub-stage 02-chameleond files to rootfs"
