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

NR_CORES := $(shell nproc)

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

# linux image
buildroot_defconfig = configs/buildroot$(XLEN)_defconfig
linux_defconfig = configs/linux$(XLEN)_defconfig
busybox_defconfig = configs/busybox$(XLEN).config

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
	make -C buildroot host-gcc-final

all: $(CC) fesvr isa-sim

# benchmark for the cache subsystem
rootfs/cachetest.elf: $(CC)
	cd ./cachetest/ && $(CC) cachetest.c -o cachetest.elf
	cp ./cachetest/cachetest.elf $@

# cool command-line tetris
rootfs/tetris: $(CC)
	cd ./vitetris/ && make clean && ./configure CC=$(CC) && make
	cp ./vitetris/tetris $@

$(RISCV)/vmlinux: $(buildroot_defconfig) $(linux_defconfig) $(busybox_defconfig) $(CC) rootfs/cachetest.elf rootfs/tetris
	mkdir -p build
	make -C buildroot
	cp buildroot/output/images/vmlinux build/vmlinux
	cp build/vmlinux $@

$(RISCV)/bbl: $(RISCV)/vmlinux
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

images: $(CC) $(RISCV)/bbl $(RISCV)/bbl.bin $(RISCV)/bbl_binary

clean:
	rm -rf $(RISCV)/vmlinux $(RISCV)/bbl $(RISCV)/bbl.bin $(RISCV)/bbl_binary build riscv-pk/build/vmlinux riscv-pk/build/bbl cachetest/*.elf rootfs/tetris rootfs/cachetest.elf
	make -C buildroot clean

clean-all: clean
	rm -rf $(RISCV) riscv-fesvr/build riscv-isa-sim/build riscv-tests/build riscv-pk/build

.PHONY: gcc vmlinux bbl bbl.bin bbl_binary images help

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
