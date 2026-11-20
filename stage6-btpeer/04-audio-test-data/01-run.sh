#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

HTTP_MIRROR_URL='http://commondatastorage.googleapis.com/chromeos-localmirror'
BUNDLE_PATH='distfiles/chameleon-bundle'
HTTP_BUNDLE_URL="${HTTP_MIRROR_URL}/${BUNDLE_PATH}"

function cloud_download() {
  # Download the specified file $1 to the path $2.
  DOWNLOAD_URL="${HTTP_BUNDLE_URL}/$1"
  echo "Downloading file bundle from ${DOWNLOAD_URL} to $2"

  wget -q -P "$2" "${DOWNLOAD_URL}"
}

function install_audio_test_data() {
  : "${ROOTFS_DIR:?ROOTFS_DIR environment variable must be set}"
  AUDIO_FILE_NAME="test-data/v1/audio-test-data.tar.gz"

  TEST_DATA_DIR="${ROOTFS_DIR}/usr/share/autotest/audio-test-data"
  if [ -d "${TEST_DATA_DIR}" ]; then
    rm -rf "${TEST_DATA_DIR}"
  fi

  mkdir -p "${TEST_DATA_DIR}"
  cloud_download "${AUDIO_FILE_NAME}" "${TEST_DATA_DIR}"

  echo "Extracting audio data file bundle..."
  tar \
  -xf "${TEST_DATA_DIR}/audio-test-data.tar.gz" -C "${TEST_DATA_DIR}" \
  --strip-components=1
  rm "${TEST_DATA_DIR}/audio-test-data.tar.gz"
  echo "Successfully extracted audio data file bundle to rootfs"
}

install_audio_test_data
