#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Check if build should be skipped
if [ -f /tmp/skip_pipewire_build ]; then
  echo "Pipewire and Wireplumber already installed. Skipping compilation."
  rm /tmp/skip_pipewire_build
  exit 0
fi

# Remove the legacy pipewire binary to prevent conflicts
apt remove -y pipewire-bin

# Build the pipewire from source
PIPEWIRE_SRC_ROOTFS_DIR="/etc/chromiumos/src/third_party/pipewire"
(cd "${PIPEWIRE_SRC_ROOTFS_DIR}" && ./autogen.sh --prefix=/usr &&
meson setup --wipe -Dbluez5=enabled -Dbluez5-codec-lc3=enabled -Dsndfile=enabled -Dpw-cat=enabled builddir &&
make -j$(nproc) &&
make install)

# Save version info
if [ -f /tmp/pipewire_version_to_install ]; then
  mkdir -p /etc/chromiumos
  mv /tmp/pipewire_version_to_install /etc/chromiumos/pipewire_version
fi

# Keep the user session login for pipewire
mkdir -p /var/lib/systemd/linger && touch /var/lib/systemd/linger/pi
