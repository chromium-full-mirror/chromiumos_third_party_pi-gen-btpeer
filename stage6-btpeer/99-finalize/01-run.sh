#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Copy the final build info file from the rootfs to the docker deploy dir, which
# will be copied to the deploy dir outside of the docker container when built
# images are exported.
echo "Copying final build info file to deploy dir"
DEPLOY_DIR="/pi-gen/deploy"
cp "${ROOTFS_DIR}/${BUILD_INFO_FILE_PATH}" "${DEPLOY_DIR}"
echo -e "Final Build info:\n$(cat "${ROOTFS_DIR}/${BUILD_INFO_FILE_PATH}")"
