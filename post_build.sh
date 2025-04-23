#! /bin/sh

TARGET_DIR=$1

if grep -q '^BR2_RISCV_32=y' ${BR2_CONFIG}; then
    ITS_FILE=../tree32.its
elif grep -q '^BR2_RISCV_64=y' ${BR2_CONFIG}; then
    ITS_FILE=../tree64.its
else
    echo "Unknown config"
    exit 1
fi

# Create FIT image
output/host/bin/mkimage -f $ITS_FILE "$BINARIES_DIR/fitImage.itb"

# Create flashable sdcard.img
support/scripts/genimage.sh -c ../genimage.cfg
