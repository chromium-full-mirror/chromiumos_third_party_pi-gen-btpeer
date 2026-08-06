#!/bin/bash -e

# Copyright 2026 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Prevent `cros lint` failing check for environment variables
: "${ROOTFS_DIR:?ROOTFS_DIR environment variable must be set}"

# Last known working phonesim version.
PHONESIM_VERSION="2.1"
PHONESIM_ZIP_ARCHIVE="https://www.kernel.org/pub/linux/network/ofono/phonesim-${PHONESIM_VERSION}.tar.gz"

# Check if already installed
INSTALLED_VERSION_FILE="${ROOTFS_DIR}/etc/chromiumos/phonesim_version"
if [ -f "${INSTALLED_VERSION_FILE}" ]; then
  INSTALLED_VERSION=$(cat "${INSTALLED_VERSION_FILE}")
  if [ "${INSTALLED_VERSION}" = "${PHONESIM_VERSION}" ]; then
    echo "Phonesim ${INSTALLED_VERSION} already installed. Skipping download."
    touch "${ROOTFS_DIR}/tmp/skip_phonesim_build"
    exit 0
  fi
fi

# Set up version info for chroot script
mkdir -p "${ROOTFS_DIR}/tmp"
echo "${PHONESIM_VERSION}" > "${ROOTFS_DIR}/tmp/phonesim_version_to_install"

THIRD_PARTY_ROOTFS_DIR="${ROOTFS_DIR}/etc/chromiumos/src/third_party"
PHONESIM_SRC_ROOTFS_DIR="${THIRD_PARTY_ROOTFS_DIR}/phonesim"
mkdir -p "${THIRD_PARTY_ROOTFS_DIR}"
if [ -d "${PHONESIM_SRC_ROOTFS_DIR}" ]; then
  echo "Removing previously clone phonesim git in rootfs"
  rm -rf "${PHONESIM_SRC_ROOTFS_DIR}"
fi

CACHE_DIR="${WORK_DIR}/cache"
mkdir -p "${CACHE_DIR}"

PHONESIM_TARBALL="${CACHE_DIR}/phonesim-${PHONESIM_VERSION}.tar.gz"
if [ ! -f "${PHONESIM_TARBALL}" ]; then
  echo "Downloading phonesim..."
  curl -L "${PHONESIM_ZIP_ARCHIVE}" -o "${PHONESIM_TARBALL}"
fi

PHONESIM_ACTUAL_SHA=$(sha512sum "${PHONESIM_TARBALL}" | awk '{print $1}')
PHONESIM_EXPECTED_SHA=$(cat "files/phonesim-${PHONESIM_VERSION}.hash")
if [ "${PHONESIM_ACTUAL_SHA}" != "${PHONESIM_EXPECTED_SHA}" ]; then
  echo "Phonesim SHA is different!! ${PHONESIM_ACTUAL_SHA} vs ${PHONESIM_EXPECTED_SHA}"
  exit 1
fi

tar -xzf "${PHONESIM_TARBALL}" -C "${THIRD_PARTY_ROOTFS_DIR}"
mv "${THIRD_PARTY_ROOTFS_DIR}/phonesim-${PHONESIM_VERSION}" "${PHONESIM_SRC_ROOTFS_DIR}"

echo "Successfully extracted phonesim source code."
