#!/bin/bash
set -e
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
git clone --depth 1 --branch 4.19.191_mt6765 https://github.com/KrutosVIP/generic_kernel_mediatek_alps.git
cd generic_kernel_mediatek_alps

# === 修复1: 全局 -fgnu89-inline ===
sed -i 's|^KBUILD_CFLAGS   := -Wall|KBUILD_CFLAGS := -Wall -fgnu89-inline|' Makefile

# === 修复2: subdir-ccflags-y -> ccflags-y ===
sed -i 's|subdir-ccflags-y += -I$(srctree)/drivers/staging/android/mtk_ion|ccflags-y += -I$(srctree)/drivers/staging/android/mtk_ion|' mm/Makefile
sed -i 's|subdir-ccflags-y += -I$(srctree)/kernel/sched|ccflags-y += -I$(srctree)/kernel/sched|' kernel/sched/extension/Makefile
sed -i 's|subdir-ccflags-y += -I$(srctree)/drivers/misc/mediatek/include/|ccflags-y += -I$(srctree)/drivers/misc/mediatek/include/|' kernel/sched/extension/Makefile

# === 修复3: mtk_ftrace.h ===
echo 'ccflags-y += -I$(srctree)/kernel/trace' >> kernel/trace/Makefile

# === 修复4: uclamp_se_set ===
python3 << 'PYEOF'
import re
h = open('kernel/sched/sched.h').read()
h = re.sub(r'(?m)^inline void uclamp_se_set\(struct uclamp_se \*uc_se,\s*\n\s*unsigned int value, bool user_defined\);',
 '''static inline void uclamp_se_set(struct uclamp_se *uc_se,
                                 unsigned int value, bool user_defined)
{
        uc_se->value = value;
        uc_se->user_defined = user_defined;
}''', h)
open('kernel/sched/sched.h','w').write(h)
c = open('kernel/sched/core.c').read()
c = re.sub(r'(?ms)^inline void uclamp_se_set\(struct uclamp_se \*uc_se.*?^\}', '', c)
open('kernel/sched/core.c','w').write(c)
PYEOF

# === 修复5: ksm_flock extern inline ===
sed -i 's|^inline void ksm_flock(struct keyslot_manager \*ksm, unsigned int flags);|extern inline void ksm_flock(struct keyslot_manager *ksm, unsigned int flags);|' include/linux/keyslot-manager.h

# === 配置 ===
make ARCH=arm64 k65v1_64_bsp_defconfig
scripts/config --enable SYSVIPC
scripts/config --enable IPC_NS
scripts/config --disable CONFIG_CC_WERROR
make ARCH=arm64 olddefconfig

# === 编译 ===
make ARCH=arm64 -j$(nproc) Image.gz-dtb KCFLAGS="-Wno-error -fgnu89-inline" 2>&1 | tee build.log
