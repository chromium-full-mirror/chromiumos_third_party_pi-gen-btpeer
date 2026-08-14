#!/bin/bash -e

# Copyright 2026 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Prevent `cros lint` failing check for environment variables
: "${ROOTFS_DIR:?ROOTFS_DIR environment variable must be set}"

# BlueZ is rebuilt from the Raspberry Pi OS Debian source package so that all
# Debian/RPi downstream patches (CVE fixes, hciattach RPi mods, etc.) are kept
# and our patches from patches/ are applied on top of them.
BLUEZ_DEB_VERSION="5.66-1+rpt2+deb12u2"
BLUEZ_UPSTREAM_VERSION="${BLUEZ_DEB_VERSION%%-*}"
BLUEZ_LOCAL_VERSION="${BLUEZ_DEB_VERSION}+cros1"
BLUEZ_POOL_URL="http://archive.raspberrypi.com/debian/pool/main/b/bluez"
BLUEZ_SRC_FILES=(
  "bluez_${BLUEZ_DEB_VERSION}.dsc"
  "bluez_${BLUEZ_DEB_VERSION}.debian.tar.xz"
  "bluez_${BLUEZ_UPSTREAM_VERSION}.orig.tar.xz"
)

FULL_BLUEZ_VERSION="${BLUEZ_LOCAL_VERSION}"

# Check if already installed
INSTALLED_VERSION_FILE="${ROOTFS_DIR}/etc/chromiumos/bluez_version"
if [ -f "${INSTALLED_VERSION_FILE}" ]; then
  INSTALLED_VERSION=$(cat "${INSTALLED_VERSION_FILE}")
  if [ "${INSTALLED_VERSION}" = "${FULL_BLUEZ_VERSION}" ]; then
    echo "BlueZ ${INSTALLED_VERSION} already installed. Skipping download and compilation."
    touch "${ROOTFS_DIR}/tmp/skip_bluez_build"
    exit 0
  fi
fi

# If we are here, we need to install. Set up version info for chroot script.
mkdir -p "${ROOTFS_DIR}/tmp"
rm -f "${ROOTFS_DIR}/tmp/skip_bluez_build"
echo "${FULL_BLUEZ_VERSION}" > "${ROOTFS_DIR}/tmp/bluez_version_to_install"
echo "${BLUEZ_LOCAL_VERSION}" > "${ROOTFS_DIR}/tmp/bluez_local_deb_version"

BLUEZ_SRC_ROOTFS_DIR="${ROOTFS_DIR}/etc/chromiumos/src/third_party/bluez-deb"
if [ -d "${BLUEZ_SRC_ROOTFS_DIR}" ]; then
  echo "Removing previous bluez source package in rootfs"
  rm -rf "${BLUEZ_SRC_ROOTFS_DIR}"
fi
mkdir -p "${BLUEZ_SRC_ROOTFS_DIR}/patches"

CACHE_DIR="${WORK_DIR}/cache"
mkdir -p "${CACHE_DIR}"

for src_file in "${BLUEZ_SRC_FILES[@]}"; do
  if [ ! -f "${CACHE_DIR}/${src_file}" ]; then
    echo "Downloading ${src_file}..."
    curl -fL "${BLUEZ_POOL_URL}/${src_file}" -o "${CACHE_DIR}/${src_file}"
  fi
done

HASH_FILE="$(pwd)/files/bluez_${BLUEZ_DEB_VERSION}.sha256"
if ! (cd "${CACHE_DIR}" && sha256sum -c --strict "${HASH_FILE}"); then
  echo "BlueZ source package checksum mismatch!"
  exit 1
fi

for src_file in "${BLUEZ_SRC_FILES[@]}"; do
  cp "${CACHE_DIR}/${src_file}" "${BLUEZ_SRC_ROOTFS_DIR}/"
done

# Stage our patches; the chroot script appends them to debian/patches/series.
if [ -d "patches" ]; then
  for patch_file in patches/*.patch; do
    if [ -f "${patch_file}" ]; then
      cp "${patch_file}" "${BLUEZ_SRC_ROOTFS_DIR}/patches/"
    fi
  done
fi

echo "Successfully staged BlueZ source package."

if [ -n "${BUILD_INFO_FILE_PATH}" ] && [ -f "${ROOTFS_DIR}/${BUILD_INFO_FILE_PATH}" ]; then
  echo "Updating build info with BlueZ version"
  BUILD_INFO_JSON=$(cat "${ROOTFS_DIR}/${BUILD_INFO_FILE_PATH}")
  BUILD_INFO_JSON=$(jq '."sources"."https://git.kernel.org/pub/scm/bluetooth/bluez.git" = $val' --arg val "${FULL_BLUEZ_VERSION}" <<< "${BUILD_INFO_JSON}")
  echo "${BUILD_INFO_JSON}" > "${ROOTFS_DIR}/${BUILD_INFO_FILE_PATH}"
fi
