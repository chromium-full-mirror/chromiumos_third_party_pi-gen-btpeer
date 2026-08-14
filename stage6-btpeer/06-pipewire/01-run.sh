#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Last known working pipewire / wireplumber version.
PIPEWIRE_VERSION="1.1.82"
WIREPLUMBER_VERSION="0.5.2"

THIRD_PARTY_ROOTFS_DIR="${ROOTFS_DIR}/etc/chromiumos/src/third_party"
PIPEWIRE_SRC_ROOTFS_DIR="${THIRD_PARTY_ROOTFS_DIR}/pipewire"
PIPEWIRE_SUBPROJECTS_SRC_ROOTFS_DIR="${PIPEWIRE_SRC_ROOTFS_DIR}/subprojects"

# Check if already installed
INSTALLED_VERSION_FILE="${ROOTFS_DIR}/etc/chromiumos/pipewire_version"
if [ -f "${INSTALLED_VERSION_FILE}" ]; then
  INSTALLED_VERSION=$(cat "${INSTALLED_VERSION_FILE}")
  if [ "${INSTALLED_VERSION}" = "${PIPEWIRE_VERSION}_${WIREPLUMBER_VERSION}" ]; then
    echo "Pipewire and Wireplumber ${INSTALLED_VERSION} already installed. Skipping download."
    touch "${ROOTFS_DIR}/tmp/skip_pipewire_build"
    exit 0
  fi
fi

# If we are here, we need to install. Set up version info for chroot script.
mkdir -p "${ROOTFS_DIR}/tmp"
echo "${PIPEWIRE_VERSION}_${WIREPLUMBER_VERSION}" > "${ROOTFS_DIR}/tmp/pipewire_version_to_install"

mkdir -p ${THIRD_PARTY_ROOTFS_DIR}
if [ -d "${PIPEWIRE_SRC_ROOTFS_DIR}" ]; then
  echo "Removing previously clone pipewire git in rootfs"
  rm -rf "${PIPEWIRE_SRC_ROOTFS_DIR}"
fi
PIPEWIRE_ARCHIVE_SITE="https://gitlab.freedesktop.org/pipewire/pipewire/-/archive"
WIREPLUMBER_ARCHIVE_SITE="https://gitlab.freedesktop.org/pipewire/wireplumber/-/archive"
PIPEWIRE_ZIP_ARCHIVE="${PIPEWIRE_ARCHIVE_SITE}/${PIPEWIRE_VERSION}/pipewire-${PIPEWIRE_VERSION}.tar.bz2"
WIREPLUMBER_ZIP_ARCHIVE="${WIREPLUMBER_ARCHIVE_SITE}/${WIREPLUMBER_VERSION}/wireplumber-${WIREPLUMBER_VERSION}.tar.bz2"

CACHE_DIR="${WORK_DIR}/cache"
mkdir -p "${CACHE_DIR}"

PIPEWIRE_TARBALL="${CACHE_DIR}/pipewire-${PIPEWIRE_VERSION}.tar.bz2"
if [ ! -f "${PIPEWIRE_TARBALL}" ]; then
  echo "Downloading pipewire..."
  curl -L "${PIPEWIRE_ZIP_ARCHIVE}" -o "${PIPEWIRE_TARBALL}"
fi

PIPEWIRE_ACTUAL_SHA=$(sha512sum "${PIPEWIRE_TARBALL}" | awk '{print $1}')
PIPEWIRE_EXPECTED_SHA=$(cat "files/pipewire-${PIPEWIRE_VERSION}.hash")
if [ "${PIPEWIRE_ACTUAL_SHA}" != "${PIPEWIRE_EXPECTED_SHA}" ]; then
  echo "Pipewire SHA is different!! ${PIPEWIRE_ACTUAL_SHA} vs ${PIPEWIRE_EXPECTED_SHA}"
  exit 1
fi

tar -xjf "${PIPEWIRE_TARBALL}" -C "${THIRD_PARTY_ROOTFS_DIR}"
mv "${THIRD_PARTY_ROOTFS_DIR}/pipewire-${PIPEWIRE_VERSION}" "${PIPEWIRE_SRC_ROOTFS_DIR}"

WIREPLUMBER_TARBALL="${CACHE_DIR}/wireplumber-${WIREPLUMBER_VERSION}.tar.bz2"
if [ ! -f "${WIREPLUMBER_TARBALL}" ]; then
  echo "Downloading wireplumber..."
  curl -L "${WIREPLUMBER_ZIP_ARCHIVE}" -o "${WIREPLUMBER_TARBALL}"
fi

WIREPLUMBER_ACTUAL_SHA=$(sha512sum "${WIREPLUMBER_TARBALL}" | awk '{print $1}')
WIREPLUMBER_EXPECTED_SHA=$(cat "files/wireplumber-${WIREPLUMBER_VERSION}.hash")
if [ "${WIREPLUMBER_ACTUAL_SHA}" != "${WIREPLUMBER_EXPECTED_SHA}" ]; then
  echo "Wireplumber SHA is different!! ${WIREPLUMBER_ACTUAL_SHA} vs ${WIREPLUMBER_EXPECTED_SHA}"
  exit 1
fi

tar -xjf "${WIREPLUMBER_TARBALL}" -C "${PIPEWIRE_SUBPROJECTS_SRC_ROOTFS_DIR}"
mv "${PIPEWIRE_SUBPROJECTS_SRC_ROOTFS_DIR}/wireplumber-${WIREPLUMBER_VERSION}" "${PIPEWIRE_SUBPROJECTS_SRC_ROOTFS_DIR}/wireplumber"

echo "Successfully extracted pipewire source code!"
