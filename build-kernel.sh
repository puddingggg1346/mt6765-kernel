#!/bin/bash
set -e
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
git clone --depth 1 --branch 4.19.191_mt6765 https://github.com/KrutosVIP/generic_kernel_mediatek_alps.git
cd generic_kernel_mediatek_alps

# 用python精确替换sched.h里的uclamp_se_set声明
python3 - << 'PYEOF'
lines = open('kernel/sched/sched.h').read().split('\n')
for i,l in enumerate(lines):
    if 'uclamp_se_set' in l and 'inline' in l and i+1 < len(lines):
        # 找到 "inline void uclamp_se_set(struct uclamp_se *uc_se,"
        # 合并下一行参数，换成 extern inline 单行声明
        if 'inline void uclamp_se_set' in l:
            lines[i] = 'extern inline void uclamp_se_set(struct uclamp_se *uc_se, unsigned int value, bool user_defined);'
            # 删除下一行的 "unsigned int value, bool user_defined);"
            if 'unsigned int value, bool user_defined' in lines[i+1]:
                del lines[i+1]
            break
open('kernel/sched/sched.h','w').write('\n'.join(lines))
PYEOF

sed -n '2363,2372p' kernel/sched/sched.h

make ARCH=arm64 k65v1_64_bsp_defconfig
scripts/config --enable SYSVIPC
scripts/config --enable IPC_NS
make ARCH=arm64 olddefconfig
make ARCH=arm64 -j$(nproc) Image.gz-dtb 2>&1 | tee build.log
