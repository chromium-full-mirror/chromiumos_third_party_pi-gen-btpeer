#!/bin/bash -e

# Copyright 2026 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Setup PulseAudio logging file
touch /var/log/pulse.log
chown pi:pi /var/log/pulse.log

# Ensure rsyslog service is enabled to start on boot
systemctl enable rsyslog
