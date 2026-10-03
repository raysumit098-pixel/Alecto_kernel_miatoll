#!/usr/bin/env bash
set -e

KERNEL_DIR="$(pwd)"
ANYKERNEL_DIR="/workspaces/AnyKernel3"
TC_DIR="/workspaces/neutron-clang"
OUT_DIR="$KERNEL_DIR/out"
DEFCONFIG="vendor/xiaomi/miatoll_defconfig"
START_TIME=$(date +"%s")

echo "=== 1. Environment Setup ==="
export PATH="$TC_DIR/bin:$PATH"
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER="raysumit"
export KBUILD_BUILD_HOST="Codespaces"

PROCS=$(nproc --all)
echo "Clang version: $(clang --version | head -n 1)"
echo "Defconfig: $DEFCONFIG"
echo "Threads: $PROCS"

mkdir -p "$OUT_DIR"

echo "=== 2. Generating Defconfig ==="
make O="$OUT_DIR" ARCH=arm64 "$DEFCONFIG"

echo "=== 3. Compiling Kernel ==="
make -j"$PROCS" O="$OUT_DIR"     ARCH=arm64     SUBARCH=arm64     CC=clang     LD=ld.lld     AR=llvm-ar     NM=llvm-nm     OBJCOPY=llvm-objcopy     OBJDUMP=llvm-objdump     STRIP=llvm-strip     CLANG_TRIPLE=aarch64-linux-gnu-     CROSS_COMPILE=aarch64-linux-gnu-     CROSS_COMPILE_ARM32=arm-linux-gnueabi-     LLVM=1     LLVM_IAS=1

echo "=== 4. Checking outputs ==="
IMAGE="$OUT_DIR/arch/arm64/boot/Image.gz"
DTBO="$OUT_DIR/arch/arm64/boot/dtbo.img"
DTB="$OUT_DIR/arch/arm64/boot/dtb.img"

if [ ! -f "$IMAGE" ]; then
    echo "ERROR: Kernel image not found at $IMAGE"
    exit 1
fi

echo "Kernel Image: $IMAGE"
echo "DTBO Image:   $DTBO"
echo "DTB Image:    $DTB"

echo "=== 5. Packaging with AnyKernel3 ==="
cd "$ANYKERNEL_DIR"
rm -f Image.gz dtbo.img dtb.img dtb *.zip

cp "$IMAGE" "$ANYKERNEL_DIR/Image.gz"
cp "$DTBO" "$ANYKERNEL_DIR/dtbo.img"
cp "$DTB" "$ANYKERNEL_DIR/dtb.img"

ZIPNAME="Ignition-Miatoll-$(date +%Y%m%d-%H%M).zip"
zip -r9 "$KERNEL_DIR/$ZIPNAME" * -x .git README.md *placeholder

END_TIME=$(date +"%s")
DIFF=$((END_TIME - START_TIME))
echo "=== BUILD SUCCESSFUL in $((DIFF / 60))m $((DIFF % 60))s! ==="
echo "Zip archive: $KERNEL_DIR/$ZIPNAME"
