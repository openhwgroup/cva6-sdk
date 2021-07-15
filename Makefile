# Makefile for RISC-V toolchain; run 'make help' for usage.

ROOT     := $(patsubst %/,%, $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
RISCV    ?= $(PWD)/install
DEST     := $(abspath $(RISCV))
PATH     := $(DEST)/bin:$(PATH)

NR_CORES := $(shell nproc)

PLATFORM := generic
FW_FDT_PATH ?=

# default configure flags
fesvr-co              = --prefix=$(RISCV) --target=riscv64-unknown-linux-gnu
isa-sim-co            = --prefix=$(RISCV) --with-fesvr=$(DEST)
gnu-toolchain-co-fast = --prefix=$(RISCV) --disable-gdb# no multilib for fast
pk-co                 = --prefix=$(RISCV) --host=riscv64-unknown-linux-gnu CC=riscv64-unknown-linux-gnu-gcc OBJDUMP=riscv64-unknown-linux-gnu-objdump
tests-co              = --prefix=$(RISCV)/target

# default make flags
fesvr-mk                = -j$(NR_CORES)
isa-sim-mk              = -j$(NR_CORES)
gnu-toolchain-libc-mk   = linux -j$(NR_CORES)
pk-mk 					= -j$(NR_CORES)
tests-mk         		= -j$(NR_CORES)

# linux image
buildroot_defconfig = configs/buildroot_defconfig
linux_defconfig = configs/linux_defconfig
busybox_defconfig = configs/busybox.config

install-dir:
	mkdir -p $(RISCV)

$(RISCV)/bin/riscv64-unknown-elf-gcc: gnu-toolchain-newlib
	cd riscv-gnu-toolchain/build;\
        make -j$(NR_CORES);\
        cd $(ROOT)

gnu-toolchain-newlib: install-dir
	mkdir -p riscv-gnu-toolchain/build
	cd riscv-gnu-toolchain/build;\
        ../configure --prefix=$(RISCV);\
        cd $(ROOT)

$(RISCV)/bin/riscv64-unknown-linux-gnu-gcc: gnu-toolchain-no-multilib
	cd riscv-gnu-toolchain/build;\
	make $(gnu-toolchain-libc-mk);\
	cd $(ROOT)

gnu-toolchain-libc: $(RISCV)/bin/riscv64-unknown-linux-gnu-gcc

gnu-toolchain-no-multilib: install-dir
	mkdir -p riscv-gnu-toolchain/build
	cd riscv-gnu-toolchain/build;\
	../configure $(gnu-toolchain-co-fast);\
	cd $(ROOT)

fesvr: install-dir $(RISCV)/bin/riscv64-unknown-linux-gnu-gcc
	mkdir -p riscv-fesvr/build
	cd riscv-fesvr/build;\
	../configure $(fesvr-co);\
	make $(fesvr-mk);\
	make install;\
	cd $(ROOT)

isa-sim: install-dir $(RISCV)/bin/riscv64-unknown-linux-gnu-gcc fesvr
	mkdir -p riscv-isa-sim/build
	cd riscv-isa-sim/build;\
	../configure $(isa-sim-co);\
	make $(isa-sim-mk);\
	make install;\
	cd $(ROOT)

tests: install-dir $(RISCV)/bin/riscv64-unknown-elf-gcc
	mkdir -p riscv-tests/build
	cd riscv-tests/build;\
	autoconf;\
	../configure $(tests-co);\
	make $(tests-mk);\
	make install;\
	cd $(ROOT)

pk: install-dir $(RISCV)/bin/riscv64-unknown-linux-gnu-gcc
	mkdir -p riscv-pk/build
	cd riscv-pk/build;\
	../configure $(pk-co);\
	make $(pk-mk);\
	make install;\
	cd $(ROOT)

all: gnu-toolchain-libc fesvr isa-sim tests pk

# benchmark for the cache subsystem
cachetest:
	cd ./cachetest/ && $(RISCV)/bin/riscv64-unknown-linux-gnu-gcc cachetest.c -o cachetest.elf
	cp ./cachetest/cachetest.elf rootfs/

# cool command-line tetris
rootfs/usr/bin/tetris:
	cd ./vitetris/ && make clean && ./configure && make CROSS_COMPILE=riscv64-unknown-linux-gnu-
	mkdir -p rootfs/usr/bin
	cp ./vitetris/tetris $@

Image: $(buildroot_defconfig) $(linux_defconfig) $(busybox_defconfig) $(RISCV)/bin/riscv64-unknown-elf-gcc $(RISCV)/bin/riscv64-unknown-linux-gnu-gcc cachetest rootfs/usr/bin/tetris
	mkdir -p build
	make -C buildroot defconfig BR2_DEFCONFIG=../$(buildroot_defconfig)
	make -C buildroot
	cp buildroot/output/images/Image build/Image
	cp build/Image Image

Image.gz: Image
	gzip -9 --force $< > $@

# U-Boot-compatible Linux image
uImage: Image.gz
	u-boot/tools/mkimage -A riscv -O linux -T kernel -C gzip -a 84000000 -e 84000000 -n "linux" -d $< $@

# U-Boot image with OpenSBI as payload
u-boot/u-boot.itb u-boot/u-boot.bin: fw_dynamic.bin
	make -C u-boot pulp-platform_occamy_defconfig OPENSBI=../fw_dynamic.bin
	make -C u-boot CROSS_COMPILE=$(RISCV)/bin/riscv64-unknown-linux-gnu- OPENSBI=../fw_dynamic.bin

# OpenSBI without payload
fw_dynamic.elf fw_dynamic.bin:
	make -C opensbi PLATFORM=$(PLATFORM) CROSS_COMPILE=$(RISCV)/bin/riscv64-unknown-linux-gnu- $(if $(FW_FDT_PATH),FW_FDT_PATH=$(FW_FDT_PATH),)
	cp opensbi/build/platform/$(PLATFORM)/firmware/fw_dynamic.elf fw_dynamic.elf
	cp opensbi/build/platform/$(PLATFORM)/firmware/fw_dynamic.bin fw_dynamic.bin

clean:
	rm -rf uImage Image.gz Image riscv-pk/build/Image riscv-pk/build/bbl cachetest/*.elf rootfs/usr/bin/tetris
	make -C u-boot clean
	make -C opensbi clean
	make -C buildroot distclean

clean-all: clean
	rm -rf riscv-fesvr/build riscv-isa-sim/build riscv-gnu-toolchain/build riscv-tests/build riscv-pk/build

.PHONY: cachetest rootfs/usr/bin/tetris

help:
	@echo "usage: $(MAKE) [RISCV='<install/here>'] [tool/img] ..."
	@echo ""
	@echo "install [tool] to \$$RISCV with compiler <flag>'s"
	@echo "    where tool can be any one of:"
	@echo "        fesvr isa-sim gnu-toolchain tests pk"
	@echo ""
	@echo "build linux images for ariane"
	@echo "    build Image with"
	@echo "        make Image"
	@echo "    build OpenSBI Kernel (with Image) with"
	@echo "        make fw_payload.elf"
	@echo ""
	@echo "There are two clean targets:"
	@echo "    Clean only buildroot"
	@echo "        make clean"
	@echo "    Clean everything (including toolchain etc)"
	@echo "        make clean-all"
	@echo ""
	@echo "defaults:"
	@echo "    RISCV='$(DEST)'"
