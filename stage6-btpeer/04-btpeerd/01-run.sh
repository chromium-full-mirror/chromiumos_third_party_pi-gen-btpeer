#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

BTPEERD_SRC_DOCKER_DIR="${CHROMIUMOS_DOCKER_DIR}/src/platform/btpeerd"

echo "Checking the state of the ChromeOS btpeerd source"
BTPEERD_COMMIT=$(cd "${BTPEERD_SRC_DOCKER_DIR}" && git config --global --add safe.directory "${BTPEERD_SRC_DOCKER_DIR}" && git rev-parse --short HEAD)
if ! $(cd "${BTPEERD_SRC_DOCKER_DIR}" && git diff-index --quiet HEAD --); then
  echo "Error: local checkout of btpeerd has uncommitted changes"
  exit 1
fi
echo "ChromeOS btpeerd source is clean and on commit '${BTPEERD_COMMIT}'"

echo "Copying ChromeOS btpeerd source to rootfs"
BTPEERD_ROOTFS_DIR="${ROOTFS_DIR}/etc/chromiumos/src/platform/btpeerd"
if [ -d "${BTPEERD_ROOTFS_DIR}" ]; then
  rm -r "${BTPEERD_ROOTFS_DIR}"
fi
mkdir -p "${BTPEERD_ROOTFS_DIR}"
rsync -a "${BTPEERD_SRC_DOCKER_DIR}/" "${BTPEERD_ROOTFS_DIR}/" \
--exclude .git --exclude .idea --exclude .vscode \
--exclude go/bin --exclude go/pkg
echo "${BTPEERD_COMMIT}" > "${BTPEERD_ROOTFS_DIR}/COMMIT"
echo "Successfully copied ChromeOS btpeerd source to rootfs"

echo "Copying ChromeOS config generated go code to rootfs"
CHROMIUMOS_CONFIG_DOCKER_DIR="${CHROMIUMOS_DOCKER_DIR}/src/config"
CHROMIUMOS_CONFIG_COMMIT=$(cd "${CHROMIUMOS_CONFIG_DOCKER_DIR}" && git config --global --add safe.directory "${CHROMIUMOS_CONFIG_DOCKER_DIR}" && git rev-parse --short HEAD)
CHROMIUMOS_CONFIG_GO_SRC_DOCKER_DIR="${CHROMIUMOS_CONFIG_DOCKER_DIR}/go"
CHROMIUMOS_CONFIG_GO_ROOTFS_DIR="${ROOTFS_DIR}/etc/chromiumos/src/config/go"
if [ -d "${CHROMIUMOS_CONFIG_GO_ROOTFS_DIR}" ]; then
  rm -r "${CHROMIUMOS_CONFIG_GO_ROOTFS_DIR}"
fi
mkdir -p "${CHROMIUMOS_CONFIG_GO_ROOTFS_DIR}"
rsync -a "${CHROMIUMOS_CONFIG_GO_SRC_DOCKER_DIR}"/* \
"${CHROMIUMOS_CONFIG_GO_ROOTFS_DIR}"
echo "Successfully copied ChromeOS config generated go code to rootfs"

echo "Updating build info"
BUILD_INFO_JSON=$(cat "${ROOTFS_DIR}/${BUILD_INFO_FILE_PATH}")
BUILD_INFO_JSON=$(jq '."sources"."https://chromium.googlesource.com/chromiumos/platform/btpeerd" = $val' --arg val "${BTPEERD_COMMIT}" <<< "${BUILD_INFO_JSON}")
BUILD_INFO_JSON=$(jq '."sources"."https://chromium.googlesource.com/chromiumos/config" = $val' --arg val "${CHROMIUMOS_CONFIG_COMMIT}" <<< "${BUILD_INFO_JSON}")
echo "${BUILD_INFO_JSON}" > "${ROOTFS_DIR}/${BUILD_INFO_FILE_PATH}"
echo -e "Current Build info:\n${BUILD_INFO_JSON}"

echo "Copying sub-stage 04-btpeerd files to rootfs"
rsync -a rootfs/* "${ROOTFS_DIR}"
echo "Successfully copied sub-stage 04-btpeerd files to rootfs"
