#!/usr/bin/env bash

# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Simple shortcut for entering an existing docker image for pi-gen.
sudo docker run -it --privileged --volumes-from=pigen_work pi-gen /bin/bash
