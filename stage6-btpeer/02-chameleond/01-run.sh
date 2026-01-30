#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Copy chameleond source to rootfs.
CHAMELEON_SRC_DOCKER_DIR="${CHROMIUMOS_DOCKER_DIR:?}/src/platform/chameleon"
CHAMELEON_ROOTFS_DIR="${ROOTFS_DIR:?}/etc/chromiumos/src/platform/chameleon"
CHAMELEOND_PROJECT_DIST_DIR="${CHAMELEON_SRC_DOCKER_DIR}/dist"

function prepare_bluetooth_grpc_chameleon {
  CHAMELEOND_DIR="${CHAMELEON_ROOTFS_DIR}/chameleond"
  TEMP_GRPC_DIR="${CHAMELEOND_DIR}/tmp"
  BLUETOOTH_GRPC_ROOT_DIR="${TEMP_GRPC_DIR}/bluetooth_grpc"
  PANDORA_STABLE_VERSION="0.0.6"
  PANDORA_TMP_DIR="${BLUETOOTH_GRPC_ROOT_DIR}/bt-test-interfaces-${PANDORA_STABLE_VERSION}"
  PANDORA_EXPERIMENTAL_VERSION="0.0.0"
  PANDORA_EXPERIMENTAL_TMP_DIR="${BLUETOOTH_GRPC_ROOT_DIR}/pandora-experimental-${PANDORA_EXPERIMENTAL_VERSION}/pandora_experimental"
  BLUESHIP_VERSION="0.0.0"
  BLUESHIP_TMP_DIR="${BLUETOOTH_GRPC_ROOT_DIR}/blueship-${BLUESHIP_VERSION}/blueship"
  BLUETOOTH_GRPC="${CHAMELEOND_DIR}"/bluetooth_grpc

  mkdir -p "${BLUETOOTH_GRPC_ROOT_DIR}"
	mkdir -p "${PANDORA_TMP_DIR}"
	mkdir -p "${BLUESHIP_TMP_DIR}"
	mkdir -p "${PANDORA_EXPERIMENTAL_TMP_DIR}"

  PANDORA_ARCHIVE_NAME="v${PANDORA_STABLE_VERSION}.tar.gz"
  PANDORA_DOWNLOAD_URL="https://github.com/google/bt-test-interfaces/archive/${PANDORA_ARCHIVE_NAME}"

  #	Download the pandora repo from the archive.

  wget -q -P "${PANDORA_TMP_DIR}" "${PANDORA_DOWNLOAD_URL}"
  tar -xvzf "${PANDORA_TMP_DIR}/${PANDORA_ARCHIVE_NAME}" --strip-components=1 -C "${PANDORA_TMP_DIR}"
  rm "${PANDORA_TMP_DIR}/${PANDORA_ARCHIVE_NAME}"

  cp -r "${BLUETOOTH_GRPC}"/pandora_experimental/interface/* "${PANDORA_EXPERIMENTAL_TMP_DIR}"
	cp -r "${BLUETOOTH_GRPC}"/blueship/interface/* "${BLUESHIP_TMP_DIR}"
# 	Copy necessary tools for installing package to the temporary directory
	cp "${BLUETOOTH_GRPC}"/setup.py "${BLUETOOTH_GRPC_ROOT_DIR}"/
	cp "${BLUETOOTH_GRPC}"/protoc-gen-custom_grpc "${BLUETOOTH_GRPC_ROOT_DIR}"/
	cp -r "${BLUETOOTH_GRPC}"/python "${BLUETOOTH_GRPC_ROOT_DIR}"
#	Move the python files of stable pandora to the root python directory
	mv "${PANDORA_TMP_DIR}"/python/pandora "${BLUETOOTH_GRPC_ROOT_DIR}"/python

  chmod 0644 "${BLUETOOTH_GRPC_ROOT_DIR}"/python/pandora/__init__.py
  chmod 0644 "${BLUETOOTH_GRPC_ROOT_DIR}"/python/pandora_experimental/__init__.py
  chmod 0644 "${BLUETOOTH_GRPC_ROOT_DIR}"/python/blueship/__init__.py
}

echo "Identifying chameleond bundle"
if [ ! -d "${CHAMELEOND_PROJECT_DIST_DIR}" ]; then
  echo "Error: No chameleond dist directory found at '${CHAMELEOND_PROJECT_DIST_DIR}'; chameleond must be packaged first with PACKAGE_CHAMELEOND=1"
  exit 1
fi
CHAMELEON_COMMIT=$(cat "${CHAMELEOND_PROJECT_DIST_DIR}"/commit)
CHAMELEOND_BUNDLE_FILENAME=$(cd "${CHAMELEOND_PROJECT_DIST_DIR}" && find * -maxdepth 1 -type f -iname "chameleond-*.tar.gz")
CHAMELEOND_BUNDLE_PATH="${CHAMELEOND_PROJECT_DIST_DIR}/${CHAMELEOND_BUNDLE_FILENAME}"
if [ ! -f "${CHAMELEOND_BUNDLE_PATH}" ]; then
  echo "Error: No chameleond bundle found in '${CHAMELEOND_PROJECT_DIST_DIR}'"
  exit 1
fi
echo "Using chameleond bundle '${CHAMELEOND_BUNDLE_PATH}'"
if [ -d "${CHAMELEON_ROOTFS_DIR}" ]; then
  echo "Removing previously extracted chameleond bundle in rootfs"
  rm -rf "${CHAMELEON_ROOTFS_DIR}"
fi
echo "Extracting chameleond bundle into rootfs"
mkdir -p "${CHAMELEON_ROOTFS_DIR}"
(cd "${CHAMELEON_ROOTFS_DIR}" && \
tar -zxf "${CHAMELEOND_BUNDLE_PATH}" --strip-components=1)
echo "Copying chameleond bundle config files to system locations in rootfs"
cp "${CHAMELEON_ROOTFS_DIR}/chameleond/utils/btservice.conf" "${ROOTFS_DIR}/etc/dbus-1/system.d/org.chromium.autotest.btservice.conf"
WIREPLUMBER_CONFIG_DIR="${ROOTFS_DIR}/home/pi/.config/wireplumber/"
install -v -o 1000 -g 1000 -d "${WIREPLUMBER_CONFIG_DIR}"
rsync --chown=1000:1000 -a "${CHAMELEON_ROOTFS_DIR}/updatable/wireplumber/"* -d "${WIREPLUMBER_CONFIG_DIR}"
PIPEWIRE_CONFIG_DIR="${ROOTFS_DIR}/etc/pipewire"
install -v -o 1000 -g 1000 -d "${PIPEWIRE_CONFIG_DIR}"
rsync --chown=1000:1000 -a "${CHAMELEON_ROOTFS_DIR}/updatable/pipewire/"* -d "${PIPEWIRE_CONFIG_DIR}"
echo "Successfully extracted chameleond bundle to rootfs at ${CHAMELEON_ROOTFS_DIR}"

# Copy btsocket source to rootfs (installed into venv via requirements.txt, then source is deleted).
BTSOCKET_SRC_DOCKER_DIR="${CHROMIUMOS_DOCKER_DIR}/src/platform/btsocket"
BTSOCKET_COMMIT=$(cd "${BTSOCKET_SRC_DOCKER_DIR}" && git config --global --add safe.directory "${BTSOCKET_SRC_DOCKER_DIR}" && git rev-parse --short HEAD)
BTSOCKET_ROOTFS_DIR="${ROOTFS_DIR}/etc/chromiumos/src/platform/btsocket"
echo "Copying ChromeOS btsocket source to rootfs"
mkdir -p "${BTSOCKET_ROOTFS_DIR}"
rsync -a "${BTSOCKET_SRC_DOCKER_DIR}/" "${BTSOCKET_ROOTFS_DIR}/" --exclude .git --exclude .idea
echo "Successfully copied ChromeOS btsocket source to rootfs"

echo "Updating build info"
BUILD_INFO_JSON=$(cat "${ROOTFS_DIR}/${BUILD_INFO_FILE_PATH:?}")
BUILD_INFO_JSON=$(jq '."sources"."https://chromium.googlesource.com/chromiumos/platform/chameleon" = $val' --arg val "${CHAMELEON_COMMIT}" <<< "${BUILD_INFO_JSON}")
BUILD_INFO_JSON=$(jq '."sources"."https://chromium.googlesource.com/chromiumos/platform/btsocket" = $val' --arg val "${BTSOCKET_COMMIT}" <<< "${BUILD_INFO_JSON}")
echo "${BUILD_INFO_JSON}" > "${ROOTFS_DIR}/${BUILD_INFO_FILE_PATH}"
echo -e "Current Build info:\n${BUILD_INFO_JSON}"

prepare_bluetooth_grpc_chameleon

echo "Copying sub-stage 02-chameleond files to rootfs"
rsync -a rootfs/* "${ROOTFS_DIR}"
echo "Successfully copied sub-stage 02-chameleond files to rootfs"
