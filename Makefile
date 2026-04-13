XLEN     ?= 64
BOARD    ?= genesys2
OUTPUT   ?= $(PWD)/install$(XLEN)_$(BOARD)
BUILD    ?= $(PWD)/build$(XLEN)_$(BOARD)

buildroot_defconfig_path = ../configs/$(BOARD)/buildroot$(XLEN)_defconfig
buildroot_external_tree_path := ../br2-ext-tree

all:
	mkdir -p $(OUTPUT)
	$(MAKE) -C buildroot O=$(BUILD) BR2_EXTERNAL="$(buildroot_external_tree_path)" BR2_DEFCONFIG=$(buildroot_defconfig_path) defconfig
	$(MAKE) -C buildroot O=$(BUILD) BINARIES_DIR=$(OUTPUT)

clean:
	rm -f $(OUTPUT)/boot.vfat $(OUTPUT)/fitImage.itb \
		$(OUTPUT)/fw_payload.bin $(OUTPUT)/fw_payload.elf \
		$(OUTPUT)/Image.gz $(OUTPUT)/rootfs.cpio $(OUTPUT)/rootfs.cpio.gz \
		$(OUTPUT)/sdcard.img \
		$(OUTPUT)/u-boot.bin $(OUTPUT)/u-boot.dtb \
		fitImage.its
	$(MAKE) -C buildroot O=$(BUILD) clean

updatedefconfigs:
	$(MAKE) -C buildroot O=$(BUILD) BR2_EXTERNAL="$(buildroot_external_tree_path)" BR2_DEFCONFIG=$(buildroot_defconfig_path) defconfig
	$(MAKE) -C buildroot O=$(BUILD) BR2_DEFCONFIG=$(buildroot_defconfig_path) savedefconfig
	$(MAKE) -C buildroot O=$(BUILD) uboot-update-defconfig
	$(MAKE) -C buildroot O=$(BUILD) linux-configure
	$(MAKE) -C buildroot O=$(BUILD) linux-update-defconfig

.PHONY: all clean updatedefconfigs
