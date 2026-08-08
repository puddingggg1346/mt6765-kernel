#!/bin/bash
set -e
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
git clone --depth 1 --branch 4.19.191_mt6765 https://github.com/KrutosVIP/generic_kernel_mediatek_alps.git
cd generic_kernel_mediatek_alps

# 修复: sched.h 中 uclamp_se_set 用 extern inline 声明（core.c已有external inline定义）
sed -i '2365c\
extern inline void uclamp_se_set(struct uclamp_se *uc_se,\
                                 unsigned int value, bool user_defined);' kernel/sched/sched.h

make ARCH=arm64 k65v1_64_bsp_defconfig
scripts/config --enable SYSVIPC
scripts/config --enable IPC_NS
make ARCH=arm64 olddefconfig
make ARCH=arm64 -j$(nproc) Image.gz-dtb 2>&1 | tee build.log
