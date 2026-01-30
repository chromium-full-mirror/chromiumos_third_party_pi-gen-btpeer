# Copyright 2026 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

ARG BASE_IMAGE=debian:bullseye
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && \
    apt-get -y install --no-install-recommends \
        git vim parted \
        quilt coreutils qemu-user-static debootstrap zerofree zip dosfstools \
        libarchive-tools libcap2-bin rsync grep udev xz-utils curl xxd file kmod bc\
        binfmt-support ca-certificates fdisk gpg pigz\
        uuid-runtime jq\
    && rm -rf /var/lib/apt/lists/*

COPY . /pi-gen/

VOLUME [ "/pi-gen/work", "/pi-gen/deploy"]
