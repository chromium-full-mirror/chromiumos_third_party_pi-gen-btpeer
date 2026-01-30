#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

BTPEERD_DIR="/etc/chromiumos/src/platform/btpeerd"
BTPEERD_EXE_PATH="${BTPEERD_DIR}/go/bin/btpeerd"
CHROMIUMOS_CONFIG_DIR="/etc/chromiumos/src/config"

# Compile btpeerd with local go compiler.
echo "Compiling btpeerd executable from go source"
"${BTPEERD_DIR}/scripts/build.sh"
if [ ! -x "${BTPEERD_EXE_PATH}" ]; then
  echo "Error: btpeerd executable not found at '${BTPEERD_EXE_PATH}'"
  exit 1
fi
echo "Successfully compiled btpeerd executable from go source"

# Enable systemd service.
systemctl enable btpeerd.service

echo "Removing ChromeOS config generated go code from rootfs"
rm -r "${CHROMIUMOS_CONFIG_DIR}"

apt-get remove --purge --yes golang-go
apt-get autoremove -y
