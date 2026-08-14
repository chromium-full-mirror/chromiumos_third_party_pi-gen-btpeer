# BlueZ Patches

Any `.patch` files placed in this directory are appended, in file name order,
to the `debian/patches/series` of the BlueZ source package during the
`02-bluez` build step. They are applied with `-p1` and fuzz 0 on top of the
Debian/RPi downstream patches, so a patch that no longer applies fails the
build.
