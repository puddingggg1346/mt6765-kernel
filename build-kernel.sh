#!/bin/bash
set -e
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
git clone --depth 1 --branch 4.19.191_mt6765 https://github.com/KrutosVIP/generic_kernel_mediatek_alps.git
cd generic_kernel_mediatek_alps
# 修复MTK的subdir-ccflags-y错误（改为本级ccflags）
sed -i 's|subdir-ccflags-y += -I$(srctree)/drivers/staging/android/mtk_ion|ccflags-y += -I$(srctree)/drivers/staging/android/mtk_ion|' mm/Makefile
sed -i 's|subdir-ccflags-y += -I$(srctree)/kernel/sched|ccflags-y += -I$(srctree)/kernel/sched|' kernel/sched/extension/Makefile
sed -i 's|subdir-ccflags-y += -I$(srctree)/drivers/misc/mediatek/include/|ccflags-y += -I$(srctree)/drivers/misc/mediatek/include/|' kernel/sched/extension/Makefile
make ARCH=arm64 k65v1_64_bsp_defconfig
scripts/config --enable SYSVIPC
scripts/config --enable IPC_NS
make ARCH=arm64 olddefconfig
make ARCH=arm64 -j$(nproc) Image.gz-dtb KBUILD_CFLAGS="-fgnu89-inline" 2>&1 | tee build.log
