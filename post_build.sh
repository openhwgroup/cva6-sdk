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

# Create the Linux image with u-boot header (uImage)
${HOST_DIR}/bin/mkimage -A riscv -O linux -T kernel -a $UIMAGE_LOAD_ADDRESS -e $UIMAGE_ENTRY_POINT -C gzip -n $IMAGE_NAME -d "$BINARIES_DIR/Image.gz" "$BINARIES_DIR/uImage"

support/scripts/genimage.sh -c ../genimage.cfg
