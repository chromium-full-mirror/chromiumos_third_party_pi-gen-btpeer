#!/bin/bash -e

# Copyright 2026 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Prevent `cros lint` failing check for environment variables
: "${ROOTFS_DIR:?ROOTFS_DIR environment variable must be set}"

THIRD_PARTY_ROOTFS_DIR="${ROOTFS_DIR}/etc/chromiumos/src/third_party"
PHONESIM_SRC_ROOTFS_DIR="${THIRD_PARTY_ROOTFS_DIR}/phonesim"
mkdir -p "${THIRD_PARTY_ROOTFS_DIR}"
if [ -d "${PHONESIM_SRC_ROOTFS_DIR}" ]; then
  echo "Removing previously clone phonesim git in rootfs"
  rm -rf "${PHONESIM_SRC_ROOTFS_DIR}"
fi

# Last known working phonesim version.
PHONESIM_VERSION="2.1"
PHONESIM_ZIP_ARCHIVE="https://git.kernel.org/pub/scm/network/ofono/phonesim.git/snapshot/phonesim-${PHONESIM_VERSION}.tar.gz"

(cd "${THIRD_PARTY_ROOTFS_DIR}" &&
  curl "${PHONESIM_ZIP_ARCHIVE}" -o "phonesim-${PHONESIM_VERSION}.tar.gz")

PHONESIM_ACTUAL_SHA=$(cd "${THIRD_PARTY_ROOTFS_DIR}" &&
 sha512sum "phonesim-${PHONESIM_VERSION}.tar.gz" | awk '{print $1}')
PHONESIM_EXPECTED_SHA=$(cat "files/phonesim-${PHONESIM_VERSION}.hash")
if [ "${PHONESIM_ACTUAL_SHA}" != "${PHONESIM_EXPECTED_SHA}" ]; then
  echo "Phonesim SHA is different!!" \
    "${PHONESIM_ACTUAL_SHA} vs " \
    "${PHONESIM_EXPECTED_SHA}"
  exit 1
fi

(cd "${THIRD_PARTY_ROOTFS_DIR}" &&
  tar -xzf "phonesim-${PHONESIM_VERSION}.tar.gz" &&
  mv "phonesim-${PHONESIM_VERSION}" "phonesim")

echo "Successfully extracted phonesim source code."
