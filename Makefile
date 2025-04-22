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


# need to run flash-sdcard with sudo -E, be careful to set the correct SDDEVICE
# Number of sector required for FWPAYLOAD partition (each sector is 512B)
FWPAYLOAD_SECTORSTART := 2048
FWPAYLOAD_SECTORSIZE = $(shell ls -l --block-size=512 $(RISCV)/fw_payload.bin | cut -d " " -f5 )
FWPAYLOAD_SECTOREND = $(shell echo $(FWPAYLOAD_SECTORSTART)+$(FWPAYLOAD_SECTORSIZE) | bc)
SDDEVICE_PART1 = $(shell lsblk $(SDDEVICE) -no PATH | head -2 | tail -1)
SDDEVICE_PART2 = $(shell lsblk $(SDDEVICE) -no PATH | head -3 | tail -1)
# Always flash uImage at 512M, easier for u-boot boot command
UIMAGE_SECTORSTART := 512M
flash-sdcard: format-sd
	dd if=$(RISCV)/fw_payload.bin of=$(SDDEVICE_PART1) status=progress oflag=sync bs=1M
	dd if=$(RISCV)/uImage         of=$(SDDEVICE_PART2) status=progress oflag=sync bs=1M

format-sd: $(SDDEVICE)
	@test -n "$(SDDEVICE)" || (echo 'SDDEVICE must be set, Ex: make flash-sdcard SDDEVICE=/dev/sdc' && exit 1)
	sgdisk --clear -g --new=1:$(FWPAYLOAD_SECTORSTART):$(FWPAYLOAD_SECTOREND) --new=2:$(UIMAGE_SECTORSTART):0 --typecode=1:3000 --typecode=2:8300 $(SDDEVICE)
# TODO: Move image creation to gendisk or buildman

clean:
	rm -f $(RISCV)/fw_payload.bin $(RISCV)/fw_payload.elf \
		$(RISCV)/uImage $(RISCV)/u-boot.bin \
		$(RISCV)/vmlinux $(RISCV)/Image $(RISCV)/Image.gz \
		$(RISCV)/rootfs.cpio $(RISCV)/rootfs.cpio.gz 

clean-all: clean
	make -C buildroot clean

.PHONY: clean clean-all
