#! /bin/sh

TARGET_DIR=$1

if grep -q '^BR2_RISCV_32=y' ${BR2_CONFIG}; then
    UIMAGE_LOAD_ADDRESS=0x80400000
    UIMAGE_ENTRY_POINT=0x80400000
    IMAGE_NAME="CV32A6Linux"
elif grep -q '^BR2_RISCV_64=y' ${BR2_CONFIG}; then
    UIMAGE_LOAD_ADDRESS=0x80200000
    UIMAGE_ENTRY_POINT=0x80200000
    IMAGE_NAME="CV64A6Linux"
else
    echo "Unknown config"
    exit 1
fi

# Create the u-boot image
# cp "$BOARD_DIR"/star64-uboot-fit-image.its "$BINARIES_DIR"
# ${HOST_DIR}/bin/mkimage -f "$BINARIES_DIR"/star64-uboot-fit-image.its -A riscv -O u-boot -T firmware "$BINARIES_DIR"/opensbi_uboot_payload.img
${HOST_DIR}/bin/mkimage -A riscv -O linux -T kernel -a $UIMAGE_LOAD_ADDRESS -e $UIMAGE_ENTRY_POINT -C gzip -n $IMAGE_NAME -d "$BINARIES_DIR"/Image.gz "$BINARIES_DIR"/uImage
