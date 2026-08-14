#!/bin/bash -e

# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

PI_CONFIG_DIR="/home/pi/.config"
SYSTEMD_USER_WANTS_PATH="/etc/systemd/user"
SOURCE_DIR="${SYSTEMD_USER_WANTS_PATH}"

# Destination directory to which the symlinks will be moved
DEST_DIR="${PI_CONFIG_DIR}/removed"

# Move the audio service symlinks in systemd.
find "${SOURCE_DIR}" -type l \( \
        -name 'wireplumber*' -o \
        -name 'pulseaudio*' -o \
        -name 'pipewire*' \) | while read -r link; do
    subdir=$(dirname "${link}")
    fullpath="${DEST_DIR}${subdir}"
    mkdir -p "${fullpath}"

    # Move the symlink
    mv "${link}" "${fullpath}"
done

echo It is intended not to start audio processes at system boot.
