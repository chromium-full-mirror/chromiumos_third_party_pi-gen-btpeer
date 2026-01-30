#!/bin/bash
# Copyright 2026 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

PLATFORM='RASPI'
export PLATFORM
BLUETOOTH_GRPC_ARGS=(
    -v
)

# Start bluetooth_grpc in venv.
echo "Starting bluetooth_grpc in venv"
CHAMELEON_DIR='/etc/chromiumos/src/platform/chameleon'
source "${CHAMELEON_DIR}"/venv/bin/activate
exec "${CHAMELEON_DIR}/utils/run_bluetooth_grpc" "${BLUETOOTH_GRPC_ARGS[@]}"
