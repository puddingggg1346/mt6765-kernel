#!/bin/bash
set -e
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
cp current_config /tmp/orig_config
git clone --depth 1 --branch 4.19.191_mt6765 https://github.com/KrutosVIP/generic_kernel_mediatek_alps.git
cd generic_kernel_mediatek_alps
cp /tmp/orig_config .config
scripts/config --enable SYSVIPC
scripts/config --enable IPC_NS
make ARCH=arm64 olddefconfig
make ARCH=arm64 -j$(nproc) Image.gz-dtb KBUILD_CFLAGS="-fgnu89-inline" 2>&1 | tee build.log
