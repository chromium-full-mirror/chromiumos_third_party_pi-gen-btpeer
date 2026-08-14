#!/bin/bash -e

# Copyright 2026 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Check if build should be skipped
if [ -f /tmp/skip_bluez_build ]; then
  echo "BlueZ already installed. Skipping compilation."
  rm /tmp/skip_bluez_build
  exit 0
fi

BLUEZ_SRC_ROOTFS_DIR="/etc/chromiumos/src/third_party/bluez-deb"
BLUEZ_LOCAL_VERSION=$(cat /tmp/bluez_local_deb_version)
rm -f /tmp/bluez_local_deb_version
# Installed binary packages built from the bluez source package.
BLUEZ_DEB_PACKAGES=(bluez bluetooth libbluetooth3 libbluetooth-dev)

cd "${BLUEZ_SRC_ROOTFS_DIR}"
rm -rf bluez
dpkg-source -x bluez_*.dsc bluez

# Append our patches to the Debian quilt series. dpkg-source applies them
# with fuzz 0 during the build, so a patch that no longer applies fails the
# build instead of being silently skipped.
for patch_file in patches/*.patch; do
  if [ -f "${patch_file}" ]; then
    patch_name=$(basename "${patch_file}")
    echo "Adding patch: ${patch_name}"
    cp "${patch_file}" "bluez/debian/patches/${patch_name}"
    echo "${patch_name}" >> bluez/debian/patches/series
  fi
done

# Give the rebuilt packages a local version so they are never confused with
# (or replaced by) the distro packages.
CHANGELOG_ENTRY=$(cat << EOF
bluez (${BLUEZ_LOCAL_VERSION}) bookworm; urgency=medium

  * Rebuild for ChromeOS btpeer with patches from pi-gen-btpeer
    stage6-btpeer/02-bluez/patches.

 -- ChromiumOS Authors <chromium-os-dev@chromium.org>  $(date -R)

EOF
)
printf '%s\n\n' "${CHANGELOG_ENTRY}" | cat - bluez/debian/changelog \
  > bluez/debian/changelog.new
mv bluez/debian/changelog.new bluez/debian/changelog

(cd bluez &&
    DEB_BUILD_OPTIONS="nocheck parallel=$(nproc)" \
    dpkg-buildpackage -b -uc -us -Pnocheck)

ARCH=$(dpkg --print-architecture)
DEB_FILES=()
for pkg in "${BLUEZ_DEB_PACKAGES[@]}"; do
  for deb_arch in "${ARCH}" all; do
    deb_file="${BLUEZ_SRC_ROOTFS_DIR}/${pkg}_${BLUEZ_LOCAL_VERSION}_${deb_arch}.deb"
    if [ -f "${deb_file}" ]; then
      DEB_FILES+=("${deb_file}")
    fi
  done
done
if [ "${#DEB_FILES[@]}" -ne "${#BLUEZ_DEB_PACKAGES[@]}" ]; then
  echo "Expected ${#BLUEZ_DEB_PACKAGES[@]} bluez packages, found: ${DEB_FILES[*]}"
  exit 1
fi

# Upgrade the distro packages in place so reverse dependencies (pi-bluetooth,
# pulseaudio-module-bluetooth, ...) stay satisfied, then hold them so later
# stages or apt upgrades can not replace the patched build.
apt-get install -y --no-install-recommends "${DEB_FILES[@]}"
apt-mark hold "${BLUEZ_DEB_PACKAGES[@]}"

# Keep the built packages for re-deploys and drop the build tree.
rm -rf bluez

for pkg in "${BLUEZ_DEB_PACKAGES[@]}"; do
  installed=$(dpkg-query -W -f='${Version}' "${pkg}")
  if [ "${installed}" != "${BLUEZ_LOCAL_VERSION}" ]; then
    echo "${pkg} is ${installed}, expected ${BLUEZ_LOCAL_VERSION}"
    exit 1
  fi
done
if [ "$(dpkg-query -W -f='${Status}' pi-bluetooth 2>/dev/null)" != \
    "install ok installed" ]; then
  echo "pi-bluetooth is no longer installed"
  exit 1
fi

# Save version info
if [ -f /tmp/bluez_version_to_install ]; then
  mkdir -p /etc/chromiumos
  mv /tmp/bluez_version_to_install /etc/chromiumos/bluez_version
fi

# Enable bluetooth service
systemctl enable bluetooth.service
