#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Remove the legacy pipewire binary to prevent conflicts
apt remove -y pipewire-bin

# Build the pipewire from source
PIPEWIRE_SRC_ROOTFS_DIR="/etc/chromiumos/src/third_party/pipewire"
(cd "${PIPEWIRE_SRC_ROOTFS_DIR}" && ./autogen.sh --prefix=/usr &&
meson setup --wipe -Dbluez5=enabled -Dbluez5-codec-lc3=enabled -Dsndfile=enabled -Dpw-cat=enabled builddir &&
make &&
make install)

# Keep the user session login for pipewire
mkdir -p /var/lib/systemd/linger && touch /var/lib/systemd/linger/pi
