#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Set default root password to standard test password (not allowed in SSH, just for local access).
echo "root:test0000" | chpasswd
