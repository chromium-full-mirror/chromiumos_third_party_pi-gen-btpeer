#!/bin/bash

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Restart network if not connected.
is_ip_found () {
    ip addr | grep inet | grep eth0 > /dev/null
}
if ! is_ip_found; then
    echo "No eth0 IP found, restarting networking service"
    service networking restart
fi

# Configure chameleond run environment.
PLATFORM='RASPI'
export PLATFORM
CHAMELEOND_ARGS=(
  -v
  --driver fpga_tio
  platform=raspi
)

# Start chameleond in venv.
echo "Starting chameleond in venv"
CHAMELEON_DIR='/etc/chromiumos/src/platform/chameleon'
# shellcheck source=/dev/null
source "${CHAMELEON_DIR}/venv/bin/activate"
exec "${CHAMELEON_DIR}/utils/run_chameleond" "${CHAMELEOND_ARGS[@]}"
