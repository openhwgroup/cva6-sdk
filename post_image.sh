#! /bin/sh

set -e

# Paths are relative to buildroot directory

ITS_TEMPLATE_FILE=../fitImage.its.template
ITS_FILE=../fitImage.its
FIT_BINARY_NAME=$BINARIES_DIR/fitImage.itb

GENIMAGE_CFG=../$2

if grep -q '^BR2_RISCV_32=y' ${BR2_CONFIG}; then
    KERNEL_LOAD_ADDRESS=0x80400000
    KERNEL_ENTRY_ADDRESS=0x80400000
    IMAGE_NAME="CV32A6Linux"
elif grep -q '^BR2_RISCV_64=y' ${BR2_CONFIG}; then
    KERNEL_LOAD_ADDRESS=0x80200000
    KERNEL_ENTRY_ADDRESS=0x80200000
    IMAGE_NAME="CV64A6Linux"
else
    echo "Unknown config"
    exit 1
fi

sed -e "s/%IMAGE_NAME%/${IMAGE_NAME}/" \
    -e "s/%KERNEL_LOAD_ADDRESS%/${KERNEL_LOAD_ADDRESS}/" \
    -e "s/%KERNEL_ENTRY_ADDRESS%/${KERNEL_ENTRY_ADDRESS}/" \
    -e "s;%BINARIES_DIR%;${BINARIES_DIR};" \
    $ITS_TEMPLATE_FILE > $ITS_FILE

# Create FIT image
${HOST_DIR}/bin/mkimage -f $ITS_FILE $FIT_BINARY_NAME

# Create flashable sdcard.img
support/scripts/genimage.sh -c $GENIMAGE_CFG
