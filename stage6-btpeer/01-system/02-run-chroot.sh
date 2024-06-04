#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Set default root password to standard test password (not allowed in SSH, just for local access).
echo "root:test0000" | chpasswd

# Enable firewall (config file customized in rootfs/etc/nftables.conf)
systemctl enable nftables.service

TESTING_RSA_PRI_KEY_PATH="/root/.ssh/testing_rsa"
chmod 0600 ${TESTING_RSA_PRI_KEY_PATH}
