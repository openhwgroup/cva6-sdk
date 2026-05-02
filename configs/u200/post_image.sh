#! /bin/sh

set -e

# Paths are relative to the buildroot directory.

ITS_TEMPLATE_FILE=../fitImage.its.template
ITS_FILE=../fitImage.its
FIT_BINARY=$BINARIES_DIR/fitImage.itb

# U200 has no SD card. The combined boot image is loaded over PCIe into
# DRAM at 0x80000000:
#     0x80000000 : fw_payload.bin (OpenSBI + U-Boot as payload)
#     0x88000000 : fitImage.itb   (kernel + DTB + ramdisk)
# U-Boot's bootcmd does `bootm 0x88000000`.
FW_OFFSET=$((128 * 1024 * 1024))   # 128 MiB
BOOT_BIN=$BINARIES_DIR/boot.bin

KERNEL_LOAD_ADDRESS=0x80200000
KERNEL_ENTRY_ADDRESS=0x80200000
IMAGE_NAME="CV64A6Linux"

sed -e "s/%IMAGE_NAME%/${IMAGE_NAME}/" \
    -e "s/%KERNEL_LOAD_ADDRESS%/${KERNEL_LOAD_ADDRESS}/" \
    -e "s/%KERNEL_ENTRY_ADDRESS%/${KERNEL_ENTRY_ADDRESS}/" \
    -e "s;%BINARIES_DIR%;${BINARIES_DIR};" \
    $ITS_TEMPLATE_FILE > $ITS_FILE

output/host/bin/mkimage -f $ITS_FILE $FIT_BINARY

cp $BINARIES_DIR/fw_payload.bin $BOOT_BIN
truncate -s $FW_OFFSET $BOOT_BIN
cat $FIT_BINARY >> $BOOT_BIN
