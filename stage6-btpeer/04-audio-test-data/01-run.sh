#!/bin/bash -e

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

HTTP_MIRROR_URL='http://commondatastorage.googleapis.com/chromeos-localmirror'
BUNDLE_PATH='distfiles/chameleon-bundle'
HTTP_BUNDLE_URL="${HTTP_MIRROR_URL}/${BUNDLE_PATH}"

function cloud_download() {
  # Download the specified file $1 to the path $2.
  DOWNLOAD_URL="${HTTP_BUNDLE_URL}/$1"
  echo "Downloading file bundle from ${DOWNLOAD_URL} to $2"

  wget -q -P "$2" "${DOWNLOAD_URL}"
}

function get_latest_wbs_bundle_name() {
  LATEST_BUNDLE=$(wget -qO - "${HTTP_BUNDLE_URL}/LATEST_WBS")
  echo "${LATEST_BUNDLE}"
}

function install_wbs_package() {
  WBS_PACKAGE_NAME=$(get_latest_wbs_bundle_name)
  WBS_TARBALL="${ROOTFS_DIR:?}/${WBS_PACKAGE_NAME}"

  cloud_download "${WBS_PACKAGE_NAME}" "${ROOTFS_DIR}"

  PA_DEFAULT_CONF="${ROOTFS_DIR}/usr/local/etc/pulse/default.pa"
  # system pulseaudio config path can be look up by
  # `su - pi -c "/usr/bin/pulseaudio --dump-conf | grep default-script-file"`
  PA_SYSTEM_DEFAULT_CONF="${ROOTFS_DIR}/etc/pulse/default.pa"
  PA_BT_POLICY="load-module module-bluetooth-policy"
  PA_BT_POLICY_OPTS="ag=false a2dp_source=false"
  PA_SUSPEND="load-module module-suspend-on-idle"
  PA_DAEMON_CONF="${ROOTFS_DIR}/etc/pulse/daemon.conf"

  if tar xf "${WBS_TARBALL}" -C "${ROOTFS_DIR}" > /dev/null; then
    # Customize the pulseaudio config here.

    # One of the PulseAudio modules, module-bluetooth-policy, will
    # automatically load the module-loopback upon detected HSP/HFP
    # activities. Update the PulseAudio default setting not to load the
    # loopback module while switching to HFP.
    for conf in "${PA_DEFAULT_CONF}" "${PA_SYSTEM_DEFAULT_CONF}"; do
        if [ -f "${conf}" ]; then
            local pat="^[[:space:]]*${PA_BT_POLICY}"
            pat+="[[:space:]]\+${PA_BT_POLICY_OPTS}[[:space:]]*$"
            if ! grep -q "${pat}" "${conf}"; then
                local src="^[[:space:]]*${PA_BT_POLICY}.*\$"
                local dst="${PA_BT_POLICY} ${PA_BT_POLICY_OPTS}"
                sed -i "s#${src}#${dst}#" "${conf}"
            fi
        fi
    done

    # Force PulseAudio to use ofono backend for HFP.
    local discover_mod="load-module module-bluetooth-discover"
    for conf in "${PA_DEFAULT_CONF}" "${PA_SYSTEM_DEFAULT_CONF}"; do
        if [ -f "${conf}" ]; then
            local cond1="^[[:space:]]*${discover_mod}"
            local cond2="${cond1}.*headset=ofono"
            if grep -q "${cond1}" "${conf}" && \
               ! grep -q "${cond2}" "${conf}"; then
                local match="^[[:space:]]*${discover_mod}.*"
                sed -i "s#${match}#& headset=ofono#" "${conf}"
            fi
        fi
    done

    # One of the PulseAudio modules, module-suspend-on-idle, will
    # trigger device disconnection if a SCO connection takes too long
    # to create on some models, e.g., asurada/spherion. Comment out
    # the module to avoid the unexpected disconnection
    if ! grep -qie "#.*${PA_SUSPEND}" "${PA_DEFAULT_CONF}"; then
        eval "sed -ie 's/${PA_SUSPEND}/#${PA_SUSPEND}/g' "\
            "${PA_DEFAULT_CONF}"
    fi
    if ! grep -qie "#.*${PA_SUSPEND}" "${PA_SYSTEM_DEFAULT_CONF}"; then
        eval "sed -ie 's/${PA_SUSPEND}/#${PA_SUSPEND}/g' "\
            "${PA_SYSTEM_DEFAULT_CONF}"
    fi

    # On upgrading to Bookworm, Raspberry Pi OS adjusted the default
    # PulseAudio script (default.pa) from `tsched=1` (dynamic timer-based
    # scheduling) to `tsched=0` (hardware interrupt fallback) to fix Broadcom
    # ALSA driver glitches. Under `tsched=0`, PulseAudio falls back to using
    # fixed fragment sizing from daemon.conf. Restore the 15ms buffer fragment
    # size used in Buster to ensure low audio buffering latency.
    PA_DAEMON_CONF="${ROOTFS_DIR}/etc/pulse/daemon.conf"
    S_FRAG="; default-fragment-size-msec = 25"
    R_FRAG="default-fragment-size-msec = 15"
    if grep -qie "${S_FRAG}" "${PA_DAEMON_CONF}"; then
        sed -i "s/${S_FRAG}/${R_FRAG}/" \
            "${PA_DAEMON_CONF}"
    fi

    S_FMT="; default-sample-format = s16le"
    R_FMT="default-sample-format = s16le"
    if grep -qie "${S_FMT}" "${PA_DAEMON_CONF}"; then
        sed -i "s/${S_FMT}/${R_FMT}/" \
            "${PA_DAEMON_CONF}"
    fi

    S_RATE="; default-sample-rate = 44100"
    R_RATE="default-sample-rate = 44100"
    if grep -qie "${S_RATE}" "${PA_DAEMON_CONF}"; then
        sed -i "s/${S_RATE}/${R_RATE}/" \
            "${PA_DAEMON_CONF}"
    fi

    S_ALT="; alternate-sample-rate = 48000"
    R_ALT="alternate-sample-rate = 44100"
    if grep -qie "${S_ALT}" "${PA_DAEMON_CONF}"; then
        sed -i "s/${S_ALT}/${R_ALT}/" \
            "${PA_DAEMON_CONF}"
    fi


    echo "Customized packages in ${WBS_PACKAGE_NAME} installed"
  else
    echo "Error in installing customized packages in ${WBS_PACKAGE_NAME}!"
  fi
  rm "${WBS_TARBALL}"
}

function install_audio_test_data() {
  AUDIO_FILE_NAME="test-data/v1/audio-test-data.tar.gz"

  TEST_DATA_DIR="${ROOTFS_DIR}/usr/share/autotest/audio-test-data"
  if [ -d "${TEST_DATA_DIR}" ]; then
    rm -rf "${TEST_DATA_DIR}"
  fi

  mkdir -p "${TEST_DATA_DIR}"
  cloud_download "${AUDIO_FILE_NAME}" "${TEST_DATA_DIR}"

  echo "Extracting audio data file bundle..."
  tar \
  -xf "${TEST_DATA_DIR}/audio-test-data.tar.gz" -C "${TEST_DATA_DIR}" \
  --strip-components=1
  rm "${TEST_DATA_DIR}/audio-test-data.tar.gz"
  echo "Successfully extracted audio data file bundle to rootfs"
}

install_audio_test_data
install_wbs_package
