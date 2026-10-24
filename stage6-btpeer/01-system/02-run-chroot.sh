#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Set default root password to standard test password (not allowed in SSH, just for local access).
echo "root:test0000" | chpasswd

# Enable firewall (config file customized in rootfs/etc/nftables.conf)
systemctl enable nftables.service

TESTING_RSA_PRI_KEY_PATH="/root/.ssh/testing_rsa"
chmod 0600 "${TESTING_RSA_PRI_KEY_PATH}"

# Enable rsyslog for redirecting logs to specific files
systemctl enable rsyslog

# Ensure unique non-localhost hostname before networking and sync DHCP hostname.
chmod 0755 /usr/local/sbin/btpeer-update-hostname
systemctl enable btpeer-hostname.service

# Use ifupdown (networking.service) as the sole DHCP manager on eth0.
systemctl disable NetworkManager.service || true
systemctl disable NetworkManager-wait-online.service || true

# Disable and mask avahi-daemon to prevent mDNS conflict storms on lab VLANs.
systemctl disable avahi-daemon.service avahi-daemon.socket || true
systemctl mask avahi-daemon.service avahi-daemon.socket
