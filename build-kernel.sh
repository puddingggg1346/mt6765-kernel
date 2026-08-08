#!/bin/bash
set -e
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
git clone --depth 1 https://github.com/lowendlibre/linux-mt6762.git
cd linux-mt6762
echo "=== CONFIGS ==="
ls arch/arm64/configs/ 2>/dev/null || echo "no configs"
echo "=== BUILD SALTS ==="
grep -rn "defconfig" arch/arm64/configs/*.defconfig 2>/dev/null | head -5
