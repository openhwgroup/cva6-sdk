# Makefile for RISC-V toolchain; run 'make help' for usage. set XLEN here to 32 or 64.

XLEN     := 64
ROOT     := $(patsubst %/,%, $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
RISCV    := $(PWD)/install$(XLEN)
DEST     := $(abspath $(RISCV))
PATH     := $(DEST)/bin:$(PATH)

TOOLCHAIN_PREFIX := $(ROOT)/buildroot/output/host/bin/riscv$(XLEN)-buildroot-linux-gnu-
CC          := $(TOOLCHAIN_PREFIX)gcc
OBJCOPY     := $(TOOLCHAIN_PREFIX)objcopy
OBJDUMP     := $(TOOLCHAIN_PREFIX)objdump
READELF     := $(TOOLCHAIN_PREFIX)readelf
MKIMAGE     := u-boot/tools/mkimage
DTC         := u-boot/scripts/dtc/dtc

NR_CORES := $(shell nproc)

# SBI options
PLATFORM := fpga/ariane
FW_FDT_PATH ?=
sbi-mk = PLATFORM=$(PLATFORM) CROSS_COMPILE=$(TOOLCHAIN_PREFIX) $(if $(FW_FDT_PATH),FW_FDT_PATH=$(FW_FDT_PATH),)
ifeq ($(XLEN), 32)
sbi-mk += PLATFORM_RISCV_ISA=rv32ima PLATFORM_RISCV_XLEN=32
else
sbi-mk += PLATFORM_RISCV_ISA=rv64imafdc PLATFORM_RISCV_XLEN=64
endif

# U-Boot options
ifeq ($(XLEN), 32)
UIMAGE_LOAD_ADDRESS := 0x80400000
UIMAGE_ENTRY_POINT  := 0x80400000
else
UIMAGE_LOAD_ADDRESS := 0x80200000
UIMAGE_ENTRY_POINT  := 0x80200000
endif

# default configure flags
fesvr-co              = --prefix=$(RISCV) --target=riscv$(XLEN)-buildroot-linux-gnu
tests-co              = --prefix=$(RISCV)/target

# specific flags and rules for 32 / 64 version
ifeq ($(XLEN), 32)
isa-sim-co            = --prefix=$(RISCV) --with-isa=RV32IMA --with-priv=MSU
pk-co                 = --prefix=$(RISCV) --host=riscv$(XLEN)-buildroot-linux-gnu CC=$(CC) OBJDUMP=$(OBJDUMP) OBJCOPY=$(OBJCOPY) --enable-32bit
else
isa-sim-co            = --prefix=$(RISCV)
pk-co                 = --prefix=$(RISCV) --host=riscv$(XLEN)-buildroot-linux-gnu CC=$(CC) OBJDUMP=$(OBJDUMP) OBJCOPY=$(OBJCOPY)
endif

# default make flags
fesvr-mk                = -j$(NR_CORES)
isa-sim-mk              = -j$(NR_CORES)
pk-mk 					= -j$(NR_CORES)
tests-mk         		= -j$(NR_CORES)
buildroot-mk       		= -j$(NR_CORES)

# linux image
buildroot_defconfig = configs/buildroot$(XLEN)_defconfig
linux_defconfig = configs/linux$(XLEN)_defconfig
busybox_defconfig = configs/busybox$(XLEN).config
uboot_defconfig := configs/uboot$(XLEN)_defconfig

install-dir:
	mkdir -p $(RISCV)

fesvr: install-dir $(CC)
	mkdir -p riscv-fesvr/build
	cd riscv-fesvr/build;\
	../configure $(fesvr-co);\
	make $(fesvr-mk);\
	make install;\
	cd $(ROOT)

isa-sim: install-dir $(CC) 
	mkdir -p riscv-isa-sim/build
	cd riscv-isa-sim/build;\
	../configure $(isa-sim-co);\
	make $(isa-sim-mk);\
	make install;\
	cd $(ROOT)

tests: install-dir $(CC)
	mkdir -p riscv-tests/build
	cd riscv-tests/build;\
	autoconf;\
	../configure $(tests-co);\
	make $(tests-mk);\
	make install;\
	cd $(ROOT)

pk: install-dir $(CC)
	mkdir -p riscv-pk/build
	cd riscv-pk/build;\
	../configure $(pk-co);\
	make $(pk-mk);\
	make install;\
	cd $(ROOT)

$(CC): $(buildroot_defconfig) $(linux_defconfig) $(busybox_defconfig)
	make -C buildroot defconfig BR2_DEFCONFIG=../$(buildroot_defconfig)
	make -C buildroot host-gcc-final $(buildroot-mk)

all: $(CC) fesvr isa-sim

# benchmark for the cache subsystem
rootfs/cachetest.elf: $(CC)
	cd ./cachetest/ && $(CC) cachetest.c -o cachetest.elf
	cp ./cachetest/cachetest.elf $@

# cool command-line tetris
rootfs/tetris: $(CC)
	cd ./vitetris/ && make clean && ./configure CC=$(CC) && make
	cp ./vitetris/tetris $@

$(RISCV)/vmlinux: install-dir $(buildroot_defconfig) $(linux_defconfig) $(busybox_defconfig) $(CC) rootfs/cachetest.elf rootfs/tetris
	mkdir -p build
	make -C buildroot $(buildroot-mk)
	cp buildroot/output/images/vmlinux $@

$(RISCV)/Image: $(RISCV)/vmlinux
	$(OBJCOPY) -O binary -R .note -R .comment -S $< $@

$(RISCV)/Image.gz: $(RISCV)/Image
	gzip -9 --force $< > $@

# U-Boot-compatible Linux image
$(RISCV)/uImage: $(RISCV)/Image.gz $(MKIMAGE)
	$(MKIMAGE) -A riscv -O linux -T kernel -a $(UIMAGE_LOAD_ADDRESS) -e $(UIMAGE_ENTRY_POINT) -C gzip -n "CV$(XLEN)A6Linux" -d $< $@

$(RISCV)/u-boot.bin: u-boot/u-boot.bin install-dir
	cp $< $@

$(MKIMAGE) $(DTC) u-boot/u-boot.bin: $(CC)
	make -C u-boot openhwgroup_cv$(XLEN)a6_genesysII_defconfig
	make -C u-boot CROSS_COMPILE=$(TOOLCHAIN_PREFIX)

# OpenSBI with u-boot as payload
$(RISCV)/fw_payload.bin: $(RISCV)/u-boot.bin
	make -C opensbi FW_PAYLOAD_PATH=$< $(sbi-mk)
	cp opensbi/build/platform/$(PLATFORM)/firmware/fw_payload.elf $(RISCV)/fw_payload.elf
	cp opensbi/build/platform/$(PLATFORM)/firmware/fw_payload.bin $(RISCV)/fw_payload.bin

# need to run flash-sdcard with sudo -E, be careful to set the correct SDDEVICE
SDDEVICE :=
# Number of sector required for FWPAYLOAD partition (each sector is 512B)
FWPAYLOAD_SECTORSTART := 2048
FWPAYLOAD_SECTORSIZE = $(shell ls -l --block-size=512 $(RISCV)/fw_payload.bin | cut -d " " -f5 )
FWPAYLOAD_SECTOREND = $(shell echo $(FWPAYLOAD_SECTORSTART)+$(FWPAYLOAD_SECTORSIZE) | bc)
# Always flash uImage at 512M, easier for u-boot boot command
UIMAGE_SECTORSTART := 512M
flash-sdcard:
	sgdisk --clear --new=1:$(FWPAYLOAD_SECTORSTART):$(FWPAYLOAD_SECTOREND) --new=2:$(UIMAGE_SECTORSTART):0 --typecode=1:3000 --typecode=2:8300 $(SDDEVICE)
	dd if=$(RISCV)/fw_payload.bin of=$(SDDEVICE)1 status=progress oflag=sync bs=1M
	dd if=$(RISCV)/uImage         of=$(SDDEVICE)2 status=progress oflag=sync bs=1M

$(RISCV)/bbl: $(RISCV)/Image
	cd build && ../riscv-pk/configure --host=riscv$(XLEN)-buildroot-linux-gnu READELF=$(READELF) OBJCOPY=$(OBJCOPY) CC=$(CC) OBJDUMP=$(OBJDUMP) --with-payload=vmlinux --enable-logo --with-logo=../configs/logo.txt CFLAGS=-fno-stack-protector
	make -C build
	cp build/bbl $@

$(RISCV)/bbl_binary: $(RISCV)/bbl
	$(OBJCOPY) -O binary $< $@

$(RISCV)/bbl.bin: $(RISCV)/bbl
	$(OBJCOPY) -S -O binary --change-addresses -0x80000000 $< $@

# specific recipes
gcc: $(CC)
vmlinux: $(RISCV)/vmlinux
bbl: $(RISCV)/bbl
bbl.bin: $(RISCV)/bbl.bin
bbl_binary: $(RISCV)/bbl_binary
fw_payload.bin: $(RISCV)/fw_payload.bin
uImage: $(RISCV)/uImage

images: $(CC) $(RISCV)/fw_payload.bin $(RISCV)/uImage

clean:
	rm -rf $(RISCV)/vmlinux $(RISCV)/bbl $(RISCV)/bbl.bin $(RISCV)/bbl_binary build riscv-pk/build/vmlinux riscv-pk/build/bbl cachetest/*.elf rootfs/tetris rootfs/cachetest.elf
	rm -rf $(RISCV)/fw_payload.bin $(RISCV)/uImage $(RISCV)/Image.gz
	make -C buildroot clean
	make -C u-boot clean
	make -C opensbi distclean

clean-all: clean
	rm -rf $(RISCV) riscv-fesvr/build riscv-isa-sim/build riscv-tests/build riscv-pk/build

.PHONY: gcc vmlinux bbl bbl.bin bbl_binary images help fw_payload.bin uImage

help:
	@echo "usage: $(MAKE) [tool/img] ..."
	@echo ""
	@echo "install compiler with"
	@echo "    make gcc"
	@echo ""
	@echo "install [tool] with compiler"
	@echo "    where tool can be any one of:"
	@echo "        gcc fesvr isa-sim tests pk"
	@echo ""
	@echo "build linux images for cva6"
	@echo "        make images"
	@echo "    for specific artefact"
	@echo "        make [vmlinux/bbl/bbl.bin]"
	@echo ""
	@echo "There are two clean targets:"
	@echo "    Clean only build object"
	@echo "        make clean"
	@echo "    Clean everything (including toolchain etc)"
	@echo "        make clean-all"
