XLEN     ?= 64
OUTPUT   ?= $(PWD)/install$(XLEN)

BUILDROOT_EXTERNAL_TREE_PATH := ../br2-ext-tree

buildroot_defconfig = configs/buildroot$(XLEN)_defconfig

all:
	mkdir -p $(OUTPUT)
	$(MAKE) -C buildroot BR2_EXTERNAL="$(BUILDROOT_EXTERNAL_TREE_PATH)" BR2_DEFCONFIG=../$(buildroot_defconfig) defconfig
	$(MAKE) -C buildroot BINARIES_DIR=$(OUTPUT)

clean:
	rm -f $(OUTPUT)/boot.vfat $(OUTPUT)/fitImage.itb \
		$(OUTPUT)/fw_payload.bin $(OUTPUT)/fw_payload.elf \
		$(OUTPUT)/Image.gz $(OUTPUT)/rootfs.cpio $(OUTPUT)/rootfs.cpio.gz \
		$(OUTPUT)/sdcard.img \
		$(OUTPUT)/u-boot.bin $(OUTPUT)/u-boot.dtb \
		image.its
	$(MAKE) -C buildroot clean

.PHONY: all clean
