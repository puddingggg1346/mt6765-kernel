#!/bin/bash
set -e
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
git clone --depth 1 https://github.com/lowendlibre/linux-mt6762.git
cd linux-mt6762
make ARCH=arm64 mt6762_defconfig
scripts/config --enable SYSVIPC
scripts/config --enable IPC_NS
make ARCH=arm64 olddefconfig
make ARCH=arm64 -j$(nproc) Image.gz-dtb
