#!/usr/bin/env bash

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script will build a custom OS image meant for ChromeOS btpeer Raspberry
# Pi devices inside of a Docker container. The image configuration files are
# generated and the main build-docker.sh script is run. See the README for more
# details.

set -e

DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
BUILD_DOCKER_SCRIPT="${DIR}/build-docker.sh"

# Prepare basic build info.
BUILD_INFO_FILE_PATH="/etc/chromiumos/raspios_cros_btpeer_build_info.json"
PI_GEN_COMMIT=$(git rev-parse --short HEAD)

# Only build btpeer images, and when specified.
touch "${DIR}/stage2/SKIP_IMAGES" # Never build normal raspi lite images.
EXPORT_IMAGE="${EXPORT_IMAGE:-1}"
if [ "${EXPORT_IMAGE}" -eq 1 ]; then
  test -f "${DIR}/stage6-btpeer/SKIP_IMAGES" && \
  rm "${DIR}/stage6-btpeer/SKIP_IMAGES"
else
  touch "${DIR}/stage6-btpeer/SKIP_IMAGES"
fi

# Allow for easy skipping of prior steps for debugging.
BTPEER_STAGE_ONLY="${BTPEER_STAGE_ONLY:-0}"
if [ "${BTPEER_STAGE_ONLY}" -eq 1 ]; then
  touch "${DIR}/stage0/SKIP"
  touch "${DIR}/stage1/SKIP"
  touch "${DIR}/stage2/SKIP"
else
  test -f "${DIR}/stage0/SKIP" && rm "${DIR}/stage0/SKIP"
  test -f "${DIR}/stage1/SKIP" && rm "${DIR}/stage1/SKIP"
  test -f "${DIR}/stage2/SKIP" && rm "${DIR}/stage2/SKIP"
fi

# Default docker settings.
CONTINUE="${CONTINUE:-0}"
PRESERVE_CONTAINER="${PRESERVE_CONTAINER:-0}"
export CONTINUE
export PRESERVE_CONTAINER

# Mount chromiumos root inside docker container so build scripts can use it.
CHROMIUMOS_DIR="${CHROMIUMOS_DIR:-"${DIR}/../../.."}"
CHROMIUMOS_DIR="${CHROMIUMOS_DIR/#\~/${HOME}}"
if [ ! -d "${CHROMIUMOS_DIR}" ]; then
  echo "Error: CHROMIUMOS_DIR '${CHROMIUMOS_DIR}' is not an existing" \
  "directory, please set CHROMIUMOS_DIR='/path/to/your/chromiumos'"
  exit 1
fi
CHROMIUMOS_DIR=$(realpath "${CHROMIUMOS_DIR}")
echo "Using CHROMIUMOS_DIR '${CHROMIUMOS_DIR}'"
CHROMIUMOS_DOCKER_DIR='/chromiumos'
PIGEN_DOCKER_OPTS="--mount type=bind,"\
"src=${CHROMIUMOS_DIR},"\
"dst=${CHROMIUMOS_DOCKER_DIR}"
export PIGEN_DOCKER_OPTS
export CHROMIUMOS_DOCKER_DIR

# Set config. Will be sourced in the build.sh run within the docker container.
echo "IMG_NAME='raspios-cros'
STAGE_LIST='stage0 stage1 stage2 stage6-btpeer'

DEPLOY_COMPRESSION='gz'

RELEASE='bookworm'

ENABLE_SSH=1

# Localize to US.
TIMEZONE_DEFAULT='America/Los_Angeles'
WPA_COUNTRY='US'
KEYBOARD_LAYOUT='English (US)'
KEYBOARD_KEYMAP='us'
LOCALE_DEFAULT='en_US.UTF-8'

# Configure default user. Will ONLY have terminal access, not SSH access.
FIRST_USER_NAME='pi'
FIRST_USER_PASS='test0000'
DISABLE_FIRST_BOOT_USER_RENAME=1

# Custom variables for scripts.
CHROMIUMOS_DOCKER_DIR='${CHROMIUMOS_DOCKER_DIR}'
export CHROMIUMOS_DOCKER_DIR
BUILD_INFO_FILE_PATH='${BUILD_INFO_FILE_PATH}'
export BUILD_INFO_FILE_PATH
PI_GEN_COMMIT='${PI_GEN_COMMIT}'
export PI_GEN_COMMIT
" > "${DIR}/config"


# compile_chameleond will make chameleond in the ChromeOS chroot so that it
# creates a new chameleond bundle.
function package_chameleond {
  echo "Packaging chameleond in ChromeOS chroot (can be skipped with PACKAGE_CHAMELEOND=0)"
  (cd "${CHROMIUMOS_DIR}" && \
  cros_sdk \
  --working-dir '/mnt/host/source/src/platform/chameleon' \
  make
  CHAMELEON_COMMIT=$(cat "${CHROMIUMOS_DIR}/src/platform/chameleon/dist/commit"))
  echo "Successfully packaged chameleond in ChromeOS chroot at chameleon commit ${CHAMELEON_COMMIT}"
}

# Package dependent ChromeOS projects like normal.
PACKAGE_CHAMELEOND="${PACKAGE_CHAMELEOND:-1}"
if [ "${PACKAGE_CHAMELEOND}" -eq 1 ]; then
  package_chameleond
fi

# Run normal raspi docker build script, passing all args.
echo "Building Raspberry Pi image for btpeer"
"${BUILD_DOCKER_SCRIPT}" $@
echo "Successfully built Raspberry Pi image for btpeer"
