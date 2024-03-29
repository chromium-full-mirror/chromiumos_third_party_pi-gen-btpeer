#!/bin/bash

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Configure chameleond run environment.
PLATFORM='RASPI'
export PLATFORM
CHAMELEOND_ARGS=(
  --driver fpga_tio
  platform=raspi
)

# Start chameleond in venv.
CHAMELEON_DIR='/etc/chromiumos/src/platform/chameleon'
source "${CHAMELEON_DIR}/venv/bin/activate"
"${CHAMELEON_DIR}/utils/run_chameleond" ${CHAMELEOND_ARGS[@]}
