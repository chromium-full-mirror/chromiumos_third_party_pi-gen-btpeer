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

### 02-chameleond

Extracts the chameleond bundle into rootfs, prepares a python venv for it, and
configures its systemd services.

Note: This does NOT utilize the chameleond makefile install process.

### 03-audio-test-data

Downloads the current audio test data bundle from GCS and extracts it to the
rootfs of the image. These files are used by Tauto bluetooth audio tests.

### 04-btpeerd

Copies btpeerd source and service config to rootfs, compiles the go code to make
the binary used as the service in the chroot, and enables the service.
