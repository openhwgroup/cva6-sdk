XLEN     ?= 64
BOARD    ?= genesys2
OUTPUT   ?= $(PWD)/install$(XLEN)_$(BOARD)
BUILD    ?= $(PWD)/build$(XLEN)_$(BOARD)

buildroot_defconfig_path = $(PWD)/configs/$(BOARD)/buildroot$(XLEN)_defconfig
buildroot_external_tree_path := $(PWD)/br2-ext-tree

all: $(BUILD)/.config
	mkdir -p $(OUTPUT)
	$(MAKE) -C buildroot O=$(BUILD) BINARIES_DIR=$(OUTPUT)

$(BUILD)/.config:
	mkdir -p $(BUILD)
	$(MAKE) -C buildroot O=$(BUILD) BR2_EXTERNAL="$(buildroot_external_tree_path)" BR2_DEFCONFIG=$(buildroot_defconfig_path) defconfig

defconfig: $(BUILD)/.config

clean:
	rm -f $(OUTPUT)/boot.vfat $(OUTPUT)/fitImage.itb \
		$(OUTPUT)/fw_payload.bin $(OUTPUT)/fw_payload.elf \
		$(OUTPUT)/Image.gz $(OUTPUT)/rootfs.cpio $(OUTPUT)/rootfs.cpio.gz \
		$(OUTPUT)/sdcard.img \
		$(OUTPUT)/u-boot.bin $(OUTPUT)/u-boot.dtb \
		$(PWD)/fitImage.its
	$(MAKE) -C buildroot O=$(BUILD) clean

updatedefconfigs:
	$(MAKE) -C buildroot O=$(BUILD) BR2_EXTERNAL="$(buildroot_external_tree_path)" BR2_DEFCONFIG=$(buildroot_defconfig_path) defconfig
	$(MAKE) -C buildroot O=$(BUILD) BR2_DEFCONFIG=$(buildroot_defconfig_path) savedefconfig
	$(MAKE) -C buildroot O=$(BUILD) uboot-update-defconfig
	$(MAKE) -C buildroot O=$(BUILD) linux-configure
	$(MAKE) -C buildroot O=$(BUILD) linux-update-defconfig

.PHONY: all defconfig clean updatedefconfigs
