#!/bin/bash -e

# Copyright 2026 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Prevent `cros lint` failing check for environment variables
: "${ROOTFS_DIR:?ROOTFS_DIR environment variable must be set}"

rsync -a rootfs/* "${ROOTFS_DIR}"

PA_SYSTEM_DEFAULT_CONF="${ROOTFS_DIR}/etc/pulse/default.pa"
PA_BT_POLICY="load-module module-bluetooth-policy"
PA_BT_POLICY_OPTS="ag=false a2dp_source=false"
PA_DISCOVER_MOD="load-module module-bluetooth-discover"
PA_SUSPEND="load-module module-suspend-on-idle"
PA_DAEMON_CONF="${ROOTFS_DIR}/etc/pulse/daemon.conf"

# One of the PulseAudio modules, module-bluetooth-policy, automatically loads
# module-loopback on HSP/HFP activity. Disable loopback when switching to HFP.
if [ -f "${PA_SYSTEM_DEFAULT_CONF}" ]; then
  pat="^[[:space:]]*${PA_BT_POLICY}"
  pat="${pat}[[:space:]]\+${PA_BT_POLICY_OPTS}[[:space:]]*$"
  if ! grep -q "${pat}" "${PA_SYSTEM_DEFAULT_CONF}"; then
    repl="${PA_BT_POLICY} ${PA_BT_POLICY_OPTS}"
    sed -i "s#^[[:space:]]*${PA_BT_POLICY}.*\$#${repl}#" \
      "${PA_SYSTEM_DEFAULT_CONF}"
  fi

  # Force PulseAudio to use the ofono backend for HFP.
  cond1="^[[:space:]]*${PA_DISCOVER_MOD}"
  cond2="${cond1}.*headset=ofono"
  if grep -q "${cond1}" "${PA_SYSTEM_DEFAULT_CONF}" &&
    ! grep -q "${cond2}" "${PA_SYSTEM_DEFAULT_CONF}"; then
    sed -i "s#^[[:space:]]*${PA_DISCOVER_MOD}.*#& headset=ofono#" \
      "${PA_SYSTEM_DEFAULT_CONF}"
  fi

  # module-suspend-on-idle can trigger disconnection if a SCO connection takes
  # too long to establish on some models (e.g., asurada/spherion).
  if ! grep -qiE "#.*${PA_SUSPEND}" "${PA_SYSTEM_DEFAULT_CONF}"; then
    sed -i "s|${PA_SUSPEND}|#${PA_SUSPEND}|g" "${PA_SYSTEM_DEFAULT_CONF}"
  fi
fi

# On Bookworm, Raspberry Pi OS switched default.pa from tsched=1 to tsched=0
# to work around Broadcom ALSA driver glitches, falling back to fixed fragment
# sizing from daemon.conf. Restore the 15ms fragment size and 44.1 kHz defaults
# used in Buster for low audio buffering latency.
if [ -f "${PA_DAEMON_CONF}" ]; then
  FRAG="default-fragment-size-msec"
  sed -i \
    -e "s/^; ${FRAG} = 25$/${FRAG} = 15/" \
    -e 's/^; default-sample-format = s16le$/default-sample-format = s16le/' \
    -e 's/^; default-sample-rate = 44100$/default-sample-rate = 44100/' \
    -e 's/^; alternate-sample-rate = 48000$/alternate-sample-rate = 44100/' \
    "${PA_DAEMON_CONF}"
fi
