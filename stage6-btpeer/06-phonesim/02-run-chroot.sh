#!/bin/bash -e

# Copyright 2026 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Check if build should be skipped
if [ -f /tmp/skip_phonesim_build ]; then
  echo "Phonesim already installed. Skipping compilation."
  rm /tmp/skip_phonesim_build
  exit 0
fi

# Build Phonesim from source
PHONESIM_SRC_ROOTFS_DIR="/etc/chromiumos/src/third_party/phonesim"
(cd "${PHONESIM_SRC_ROOTFS_DIR}" &&
    ./bootstrap &&
    ./configure --prefix=/usr &&
    make -j$(nproc) &&
    make install)

# Save version info
if [ -f /tmp/phonesim_version_to_install ]; then
  mkdir -p /etc/chromiumos
  mv /tmp/phonesim_version_to_install /etc/chromiumos/phonesim_version
fi

# Write phonesim config
mkdir -p /etc/ofono && touch /etc/ofono/phonesim.conf
cat << EOF > /etc/ofono/phonesim.conf
[phonesim]
Driver=phonesim
Address=127.0.0.1
Port=12345
EOF
