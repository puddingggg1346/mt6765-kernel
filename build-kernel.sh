#!/bin/bash
set -e
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
git clone --depth 1 --branch 4.19.191_mt6765 https://github.com/KrutosVIP/generic_kernel_mediatek_alps.git
cd generic_kernel_mediatek_alps

# === MTK源码自身的include bug修复(必需) ===
sed -i 's|subdir-ccflags-y += -I$(srctree)/drivers/staging/android/mtk_ion|ccflags-y += -I$(srctree)/drivers/staging/android/mtk_ion|' mm/Makefile
sed -i 's|subdir-ccflags-y += -I$(srctree)/kernel/sched|ccflags-y += -I$(srctree)/kernel/sched|' kernel/sched/extension/Makefile
sed -i 's|subdir-ccflags-y += -I$(srctree)/drivers/misc/mediatek/include/|ccflags-y += -I$(srctree)/drivers/misc/mediatek/include/|' kernel/sched/extension/Makefile
echo 'ccflags-y += -I$(srctree)/kernel/trace' >> kernel/trace/Makefile

# === uclamp_se_set 补全(源码缺函数体) ===
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

# === 修复hal_kpd.c: for漏花括号导致misleading-indentation ===
python3 << 'INNER'
p = 'drivers/input/keyboard/mediatek/mt6765/hal_kpd.c'
c = open(p).read()
old = """        for (i = 0; i < KPD_NUM_MEMS; i++)
                keymap_state[i] = kpd_keymap_state[i];
                kpd_info("init_keymap_state done: %x %x %x %x %x!\n",
                        keymap_state[0], keymap_state[1], keymap_state[2],
                 keymap_state[3], keymap_state[4]);"""
new = """        for (i = 0; i < KPD_NUM_MEMS; i++) {
                keymap_state[i] = kpd_keymap_state[i];
        }
        kpd_info("init_keymap_state done: %x %x %x %x %x!\n",
                keymap_state[0], keymap_state[1], keymap_state[2],
                keymap_state[3], keymap_state[4]);"""
c = c.replace(old, new)
open(p,'w').write(c)
INNER
# === 配置 ===
make ARCH=arm64 k65v1_64_bsp_defconfig
scripts/config --enable SYSVIPC
scripts/config --enable IPC_NS
scripts/config --disable CONFIG_CC_WERROR
make ARCH=arm64 olddefconfig

# === 编译(gcc-9, 老GCC, 无需额外兼容flag) ===
make ARCH=arm64 -j$(nproc) Image.gz-dtb 2>&1 | tee build.log
