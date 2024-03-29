#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

echo "Copying ChromeOS btpeerd source to rootfs"
BTPEERD_SRC_DOCKER_DIR="${CHROMIUMOS_DOCKER_DIR}/src/platform/btpeerd"
BTPEERD_ROOTFS_DIR="${ROOTFS_DIR}/etc/chromiumos/src/platform/btpeerd"
if [ -d "${BTPEERD_ROOTFS_DIR}" ]; then
  rm -r "${BTPEERD_ROOTFS_DIR}"
fi
mkdir -p "${BTPEERD_ROOTFS_DIR}"
rsync -a "${BTPEERD_SRC_DOCKER_DIR}/" "${BTPEERD_ROOTFS_DIR}/" \
--exclude .git --exclude .idea --exclude .vscode \
--exclude go/bin --exclude go/pkg
echo "Successfully copied ChromeOS btpeerd source to rootfs"

echo "Copying ChromeOS config generated go code to rootfs"
CHROMIUMOS_CONFIG_GO_SRC_DOCKER_DIR="${CHROMIUMOS_DOCKER_DIR}/src/config/go"
CHROMIUMOS_CONFIG_GO_ROOTFS_DIR="${ROOTFS_DIR}/etc/chromiumos/src/config/go"
if [ -d "${CHROMIUMOS_CONFIG_GO_ROOTFS_DIR}" ]; then
  rm -r "${CHROMIUMOS_CONFIG_GO_ROOTFS_DIR}"
fi
mkdir -p "${CHROMIUMOS_CONFIG_GO_ROOTFS_DIR}"
rsync -a "${CHROMIUMOS_CONFIG_GO_SRC_DOCKER_DIR}"/* \
"${CHROMIUMOS_CONFIG_GO_ROOTFS_DIR}"
echo "Successfully copied ChromeOS config generated go code to rootfs"

echo "Copying sub-stage 04-btpeerd files to rootfs"
rsync -a rootfs/* "${ROOTFS_DIR}"
echo "Successfully copied sub-stage 04-btpeerd files to rootfs"
