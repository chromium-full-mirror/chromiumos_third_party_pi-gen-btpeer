# stage6-btpeer

This stage turns the lite Raspberry Pi image into an image for ChromeOS btpeers.

The chromiumos dir is expected to be mounted in the Docker container at `/chromiumos`.

## Sub-stages

### 01-system

Configures core systems to allow the device to work in a lab environment.

* Configures sshd settings
  * Only allows ssh as `root` with the testing_rsa private key.
  * Adds an ssh banner that describes the device.
  * Configures SFTP to use SFTP server bundled with sshd.
  * Allows for many concurrent ssh sessions.
* Sets default `root` user password for local access and to avoid warnings about it being unset.
* Disables wifi service, as btpeers do not ever use wifi.
* Includes utility packages for remote debugging (e.g. `vim`).
* Includes `rsyslog` to retain system logs for mobly testing.

### 02-bluez

Rebuilds BlueZ from the Raspberry Pi OS Debian source package, enabling custom
patches to be applied on top of the Debian/RPi downstream patches.

* Downloads the pinned `bluez` source package from `archive.raspberrypi.com`
  and verifies it against `files/bluez_<version>.sha256`.
* Appends any `.patch` files located in `02-bluez/patches/` to the Debian quilt
  series (applied with fuzz 0).
* Builds the packages with `dpkg-buildpackage`, installs `bluez`, `bluetooth`,
  `libbluetooth3` and `libbluetooth-dev` as `<version>+cros1`, and holds them.
* Installs the btpeer `bluetooth.service` and enables it.

### 03-chameleond

Extracts the chameleond bundle into rootfs, prepares a python venv for it, and
configures its systemd services.

Note: This does NOT utilize the chameleond makefile install process.

### 04-audio-test-data

Downloads the current audio test data bundle from GCS and extracts it to the
rootfs of the image. These files are used by Tauto bluetooth audio tests.

### 05-btpeerd

Copies btpeerd source and service config to rootfs, compiles the go code to make
the binary used as the service in the chroot, and enables the service.

### 06-pipewire

Builds PipeWire and WirePlumber from source with BlueZ and LC3 codec support.

### 07-phonesim

Builds ofono-phonesim from source and configures `/etc/ofono/phonesim.conf`.

### 08-pulseaudio

* Setup pulseaudio log to /var/log/pulse.log with logrotate.
