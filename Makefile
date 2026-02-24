XLEN     ?= 64
DEVICE   ?= "genesysII"
OUTPUT   ?= $(PWD)/install$(XLEN)_$(DEVICE)
BUILDROOT_DEFCONFIG ?= buildroot$(XLEN)_$(DEVICE)_defconfig

buildroot_defconfig_path = ../configs/$(BUILDROOT_DEFCONFIG)
buildroot_external_tree_path := ../br2-ext-tree

all:
	mkdir -p $(OUTPUT)
	$(MAKE) -C buildroot BR2_EXTERNAL="$(buildroot_external_tree_path)" BR2_DEFCONFIG=$(buildroot_defconfig_path) defconfig
	$(MAKE) -C buildroot BINARIES_DIR=$(OUTPUT)

clean:
	rm -f $(OUTPUT)/boot.vfat $(OUTPUT)/fitImage.itb \
		$(OUTPUT)/fw_payload.bin $(OUTPUT)/fw_payload.elf \
		$(OUTPUT)/Image.gz $(OUTPUT)/rootfs.cpio $(OUTPUT)/rootfs.cpio.gz \
		$(OUTPUT)/sdcard.img \
		$(OUTPUT)/u-boot.bin $(OUTPUT)/u-boot.dtb \
		fitImage.its
	$(MAKE) -C buildroot clean

updatedefconfigs:
	$(MAKE) -C buildroot BR2_EXTERNAL="$(buildroot_external_tree_path)" BR2_DEFCONFIG=$(buildroot_defconfig_path) defconfig
	$(MAKE) -C buildroot BR2_DEFCONFIG=$(buildroot_defconfig_path) savedefconfig
	$(MAKE) -C buildroot linux-configure
	$(MAKE) -C buildroot linux-update-defconfig

.PHONY: all clean updatedefconfigs
