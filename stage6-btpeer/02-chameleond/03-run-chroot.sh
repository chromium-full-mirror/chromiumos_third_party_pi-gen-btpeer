#!/bin/bash -e

# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# ofono.conf needs to be updated to allow `pi` user access
OFONO_CONF="/etc/dbus-1/system.d/ofono.conf"
TMP_CONF="/tmp/ofono.conf.tmp"
if ! grep -q 'policy user="pi"' "${OFONO_CONF}"; then
    echo "Updating ${OFONO_CONF} with policy user=pi"
    # Clear temporary file first
    echo -n > "${TMP_CONF}"

    while read -r line
    do
    # Insert pi user permissions right before the root policy
    if echo ${line} | grep -q 'policy user="root"'; then
        echo '<policy user="pi">' >> "${TMP_CONF}"
        echo '<allow send_destination="org.ofono" />' >> "${TMP_CONF}"
        echo '</policy>' >> "${TMP_CONF}"
        echo '' >> "${TMP_CONF}"
    fi
    # Copy the remaining lines as-is so the original isn't modified
    echo "${line}" >> "${TMP_CONF}"
    done < "${OFONO_CONF}"

    cp "${TMP_CONF}" "${OFONO_CONF}"
fi
