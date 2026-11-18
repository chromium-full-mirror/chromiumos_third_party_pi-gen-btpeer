#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Verify required environment variables are set
: "${ROOTFS_DIR:?ROOTFS_DIR must be set}"
: "${BUILD_INFO_FILE_PATH:?BUILD_INFO_FILE_PATH must be set}"

# Copy the final build info file from the rootfs to the docker deploy dir, which
# will be copied to the deploy dir outside of the docker container when built
# images are exported.
# Enforce /etc permissions are 755 to prevent PulseAudio startup failures.
chmod 755 "${ROOTFS_DIR}/etc"

if grep -rnEi '^License:.*\b(AGPL|Affero)\b' \
  "${ROOTFS_DIR}/usr/share/doc/"*/copyright; then
  echo "Error: unexpected package detected in rootfs" >&2
  exit 1
fi

while IFS=$'\t' read -r status pkg section; do
  if [[ "${status}" != "installed" ]]; then
    continue
  fi
  if [[ "${section}" =~ ^(non-free|non-free-firmware|contrib)(/|$) ]]; then
    case "${pkg}" in
      bluez-firmware|raspi-firmware)
        ;;
      *)
        echo "Error: unexpected ${section} package '${pkg}' installed" >&2
        exit 1
        ;;
    esac
  fi
done < <(
  dpkg-query --admindir="${ROOTFS_DIR}/var/lib/dpkg" \
    -W -f='${db:Status-Status}\t${Package}\t${Section}\n'
)

echo "Copying final build info file to deploy dir"
DEPLOY_DIR="/pi-gen/deploy"
cp "${ROOTFS_DIR}/${BUILD_INFO_FILE_PATH}" "${DEPLOY_DIR}"
echo -e "Final Build info:\n$(cat "${ROOTFS_DIR}/${BUILD_INFO_FILE_PATH}")"
