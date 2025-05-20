# Makefile for RISC-V toolchain; run 'make help' for usage. set XLEN here to 32 or 64.

XLEN     ?= 64
RISCV    := $(PWD)/install$(XLEN)

BUILDROOT_EXTERNAL_TREE_PATH := ../br2-ext-tree

# configs
buildroot_defconfig = configs/buildroot$(XLEN)_defconfig
linux_defconfig = configs/linux$(XLEN)_defconfig

all: $(buildroot_defconfig) $(linux_defconfig)
	mkdir -p $(RISCV)
	make -C buildroot BR2_EXTERNAL="$(BUILDROOT_EXTERNAL_TREE_PATH)" BR2_DEFCONFIG=../$(buildroot_defconfig) defconfig
	make -C buildroot BINARIES_DIR=$(RISCV)

# Possible flash command:
# dd if=install64/sdcard.img of=/dev/sd<device> status=progress oflag=sync bs=4M conv=sparse

clean:
	rm -f $(RISCV)/fw_payload.bin $(RISCV)/fw_payload.elf \
		$(RISCV)/uImage $(RISCV)/u-boot.bin \
		$(RISCV)/vmlinux $(RISCV)/Image $(RISCV)/Image.gz \
		$(RISCV)/rootfs.cpio $(RISCV)/rootfs.cpio.gz 

clean-all: clean
	make -C buildroot clean

.PHONY: all clean clean-all
