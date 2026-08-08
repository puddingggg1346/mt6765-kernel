#!/bin/bash
set -e
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
git clone --depth 1 --branch 4.19.191_mt6765 https://github.com/KrutosVIP/generic_kernel_mediatek_alps.git
cd generic_kernel_mediatek_alps

# 修复MTK的subdir-ccflags-y
sed -i 's|subdir-ccflags-y += -I$(srctree)/drivers/staging/android/mtk_ion|ccflags-y += -I$(srctree)/drivers/staging/android/mtk_ion|' mm/Makefile
sed -i 's|subdir-ccflags-y += -I$(srctree)/kernel/sched|ccflags-y += -I$(srctree)/kernel/sched|' kernel/sched/extension/Makefile
sed -i 's|subdir-ccflags-y += -I$(srctree)/drivers/misc/mediatek/include/|ccflags-y += -I$(srctree)/drivers/misc/mediatek/include/|' kernel/sched/extension/Makefile

# 修复 uclamp_se_set: sched.h加static inline实现, core.c删定义
python3 << 'PYEOF'
import re
h = open('kernel/sched/sched.h').read()
# 替换 "inline void uclamp_se_set(...)" 声明为 static inline 实现
h = re.sub(r'(?m)^inline void uclamp_se_set\(struct uclamp_se \*uc_se,\s*\n\s*unsigned int value, bool user_defined\);',
 '''static inline void uclamp_se_set(struct uclamp_se *uc_se,
                                 unsigned int value, bool user_defined)
{
        uc_se->value = value;
        uc_se->user_defined = user_defined;
}''', h)
open('kernel/sched/sched.h','w').write(h)

# 删除 core.c 里的 uclamp_se_set 定义(避免重复)
c = open('kernel/sched/core.c').read()
c = re.sub(r'(?ms)^inline void uclamp_se_set\(struct uclamp_se \*uc_se.*?^\}', '', c)
open('kernel/sched/core.c','w').write(c)
PYEOF

make ARCH=arm64 k65v1_64_bsp_defconfig
scripts/config --enable SYSVIPC
scripts/config --enable IPC_NS
make ARCH=arm64 olddefconfig
make ARCH=arm64 -j$(nproc) Image.gz-dtb 2>&1 | tee build.log
