#!/bin/bash
set -e
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
git clone --depth 1 --branch 4.19.191_mt6765 https://github.com/KrutosVIP/generic_kernel_mediatek_alps.git
cd generic_kernel_mediatek_alps
make ARCH=arm64 k65v1_64_bsp_defconfig
scripts/config --enable SYSVIPC
scripts/config --enable IPC_NS
make ARCH=arm64 olddefconfig
# gnu89-inline: 解决老内核在新GCC下的always_inline问题
make ARCH=arm64 -j$(nproc) Image.gz-dtb KBUILD_CFLAGS="-fgnu89-inline" 2>&1 | tee build.log
