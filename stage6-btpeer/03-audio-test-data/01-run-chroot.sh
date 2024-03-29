#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Give read and write permission to all the test files
TEST_DATA_DIR='/usr/share/autotest/audio-test-data'
chmod ugo+rw -R "${TEST_DATA_DIR}"
