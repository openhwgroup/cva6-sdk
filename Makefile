# Makefile for RISC-V toolchain; run 'make help' for usage.

ROOT     := $(patsubst %/,%, $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# linux image
buildroot_defconfig = configs/buildroot_defconfig
linux_defconfig = configs/linux_defconfig
busybox_defconfig = configs/busybox.config

all: bbl

# benchmark for the cache subsystem
cachetest:
	$(RISCV)/bin/riscv64-unknown-linux-gnu-gcc cachetest/cachetest.c -o cachetest/cachetest.elf
	cp ./cachetest/cachetest.elf rootfs/

# cool command-line tetris
rootfs/tetris:
	cd ./vitetris && ./configure CC=$(RISCV)/bin/riscv64-unknown-linux-gnu-gcc
	make -C ./vitetris/
	cp ./vitetris/tetris $@

vmlinux: $(buildroot_defconfig) $(linux_defconfig) $(busybox_defconfig) cachetest rootfs/tetris
	make -C buildroot defconfig BR2_DEFCONFIG=../$(buildroot_defconfig)
	make -C buildroot
	cp buildroot/output/images/vmlinux vmlinux

bbl: vmlinux
	mkdir -p riscv-pk/build
	cd riscv-pk/build && ../configure --host=riscv64-unknown-linux-gnu --with-payload=../../vmlinux --enable-logo --with-logo=../../configs/logo.txt
	make -C riscv-pk/build
	cp riscv-pk/build/bbl bbl

bbl_binary: bbl
	riscv64-unknown-elf-objcopy -O binary bbl bbl_binary

clean:
	rm -rf vmlinux bbl bbl.bin riscv-pk/build/vmlinux riscv-pk/build cachetest/*.elf rootfs/tetris
	# make -C buildroot distclean
	make -C vitetris clean

bbl.bin: bbl
	riscv64-unknown-elf-objcopy -S -O binary --change-addresses -0x80000000 $< $@

.PHONY: cachetest rootfs/tetris

help:
	@echo "usage: $(MAKE) [tool/img] ..."
	@echo ""
	@echo "build linux images for ariane"
	@echo "    build vmlinux with"
	@echo "        make vmlinux"
	@echo "    build bbl (with vmlinux) with"
	@echo "        make bbl"
