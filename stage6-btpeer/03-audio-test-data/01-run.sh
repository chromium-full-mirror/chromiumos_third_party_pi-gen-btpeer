#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

HTTP_MIRROR_URL='http://commondatastorage.googleapis.com/chromeos-localmirror'
BUNDLE_PATH='distfiles/chameleon-bundle'
HTTP_BUNDLE_URL="${HTTP_MIRROR_URL}/${BUNDLE_PATH}"
AUDIO_FILE_BUNDLE_URL="${HTTP_BUNDLE_URL}/test-data/v1/audio-test-data.tar.gz"

# Download the specified file $1 to the path $2.
TEST_DATA_DIR="${ROOTFS_DIR}/usr/share/autotest/audio-test-data"
if [ -d "${TEST_DATA_DIR}" ]; then
  rm -rf "${TEST_DATA_DIR}"
fi
mkdir -p "${TEST_DATA_DIR}"
echo "Downloading audio data file bundle from ${AUDIO_FILE_BUNDLE_URL}..."
wget -q -P "${TEST_DATA_DIR}" "${AUDIO_FILE_BUNDLE_URL}"
echo "Extracting audio data file bundle..."
tar \
-xf "${TEST_DATA_DIR}/audio-test-data.tar.gz" -C "${TEST_DATA_DIR}" \
--strip-components=1
rm "${TEST_DATA_DIR}/audio-test-data.tar.gz"
echo "Successfully extracted audio data file bundle to rootfs"
