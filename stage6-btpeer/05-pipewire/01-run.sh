#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

THIRD_PARTY_ROOTFS_DIR="${ROOTFS_DIR}/etc/chromiumos/src/third_party"
PIPEWIRE_SRC_ROOTFS_DIR="${THIRD_PARTY_ROOTFS_DIR}/pipewire"
PIPEWIRE_SUBPROJECTS_SRC_ROOTFS_DIR="${PIPEWIRE_SRC_ROOTFS_DIR}/subprojects"
mkdir -p ${THIRD_PARTY_ROOTFS_DIR}
if [ -d "${PIPEWIRE_SRC_ROOTFS_DIR}" ]; then
  echo "Removing previously clone pipewire git in rootfs"
  rm -rf "${PIPEWIRE_SRC_ROOTFS_DIR}"
fi

# Last known working pipewire / wireplumber version.
PIPEWIRE_VERSION="1.1.82"
WIREPLUMBER_VERSION="0.5.2"
PIPEWIRE_ARCHIVE_SITE="https://gitlab.freedesktop.org/pipewire/pipewire/-/archive"
WIREPLUMBER_ARCHIVE_SITE="https://gitlab.freedesktop.org/pipewire/wireplumber/-/archive"
PIPEWIRE_ZIP_ARCHIVE="${PIPEWIRE_ARCHIVE_SITE}/${PIPEWIRE_VERSION}/pipewire-${PIPEWIRE_VERSION}.tar.bz2"
WIREPLUMBER_ZIP_ARCHIVE="${WIREPLUMBER_ARCHIVE_SITE}/${WIREPLUMBER_VERSION}/wireplumber-${WIREPLUMBER_VERSION}.tar.bz2"

(cd ${THIRD_PARTY_ROOTFS_DIR} &&
  curl ${PIPEWIRE_ZIP_ARCHIVE} -o "pipewire-${PIPEWIRE_VERSION}.tar.bz2")

PIPEWIRE_ACTUAL_SHA=$(cd ${THIRD_PARTY_ROOTFS_DIR} &&
 sha512sum "pipewire-${PIPEWIRE_VERSION}.tar.bz2" | awk '{print $1}')
PIPEWIRE_EXPECTED_SHA=$(cat "files/pipewire-${PIPEWIRE_VERSION}.hash")
if [ "${PIPEWIRE_ACTUAL_SHA}" != "${PIPEWIRE_EXPECTED_SHA}" ]; then
  echo "Pipewire SHA is different!! ${PIPEWIRE_ACTUAL_SHA} vs ${PIPEWIRE_EXPECTED_SHA}"
  exit 1
fi

(cd ${THIRD_PARTY_ROOTFS_DIR} &&
  bzip2 -fd "pipewire-${PIPEWIRE_VERSION}.tar.bz2" &&
  tar -xf "pipewire-${PIPEWIRE_VERSION}.tar" &&
  mv "pipewire-${PIPEWIRE_VERSION}" "pipewire")

(cd ${PIPEWIRE_SUBPROJECTS_SRC_ROOTFS_DIR} &&
  curl ${WIREPLUMBER_ZIP_ARCHIVE} -o "wireplumber-${WIREPLUMBER_VERSION}.tar.bz2")

xxx=$(cd ${PIPEWIRE_SUBPROJECTS_SRC_ROOTFS_DIR} &&
  ls -lah "wireplumber-${WIREPLUMBER_VERSION}.tar.bz2")
echo $xxx

echo $WIREPLUMBER_ZIP_ARCHIVE

WIREPLUMBER_ACTUAL_SHA=$(cd ${PIPEWIRE_SUBPROJECTS_SRC_ROOTFS_DIR} &&
sha512sum "wireplumber-${WIREPLUMBER_VERSION}.tar.bz2" | awk '{print $1}')
WIREPLUMBER_EXPECTED_SHA=$(cat "files/wireplumber-${WIREPLUMBER_VERSION}.hash")
if [ "${WIREPLUMBER_ACTUAL_SHA}" != "${WIREPLUMBER_EXPECTED_SHA}" ]; then
  echo "Wireplumber SHA is different!! ${WIREPLUMBER_ACTUAL_SHA} vs ${WIREPLUMBER_EXPECTED_SHA}"
  exit 1
fi

(cd ${PIPEWIRE_SUBPROJECTS_SRC_ROOTFS_DIR} &&
  bzip2 -fd "wireplumber-${WIREPLUMBER_VERSION}.tar.bz2" &&
  tar -xf "wireplumber-${WIREPLUMBER_VERSION}.tar" &&
  mv "wireplumber-${WIREPLUMBER_VERSION}" "wireplumber")

echo "Successfully extracted pipewire source code!"
