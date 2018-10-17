# Makefile for RISC-V toolchain; run 'make help' for usage.

ROOT     := $(patsubst %/,%, $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
RISCV    ?= $(PWD)/install
DEST     := $(abspath $(RISCV))
PATH     := $(DEST)/bin:$(PATH)

NR_CORES := 4

# default configure flags
fesvr-co              = --prefix=$(RISCV) --target=riscv64-unknown-elf
isa-sim-co            = --prefix=$(RISCV) --with-fesvr=$(DEST)
gnu-toolchain-co      = --prefix=$(RISCV) --enable-multilib
gnu-toolchain-co-fast = --prefix=$(RISCV) --with-arch=rv64imac --with-abi=lp64 # no multilib for fast
pk-co                 = --prefix=$(RISCV) --host=riscv64-unknown-elf
tests-co              = --prefix=$(RISCV)/target

#default make flags
fesvr-mk                = -j$(NR_CORES)
isa-sim-mk              = -j$(NR_CORES)
gnu-toolchain-newlib-mk = -j$(NR_CORES)
gnu-toolchain-libc-mk   = linux -j$(NR_CORES)
pk-mk 					= -j$(NR_CORES)
tests-mk         		= -j$(NR_CORES)


install-dir:
	mkdir -p $(RISCV)


gnu-toolchain-newlib: gnu-toolchain-no-multilib
	cd riscv-gnu-toolchain/build;\
	make $(gnu-toolchain-newlib-mk);\
	cd $(ROOT)

gnu-toolchain-libc: gnu-toolchain
	cd riscv-gnu-toolchain/build;\
	make $(gnu-toolchain-libc-mk);\
	cd $(ROOT)

gnu-toolchain: install-dir
	mkdir -p riscv-gnu-toolchain/build
	cd riscv-gnu-toolchain/build;\
	../configure $(gnu-toolchain-co);\
	cd $(ROOT)

gnu-toolchain-no-multilib: install-dir
	mkdir -p riscv-gnu-toolchain/build
	cd riscv-gnu-toolchain/build;\
	../configure $(gnu-toolchain-co-fast);\
	cd $(ROOT)
	
fesvr: install-dir gnu-toolchain-newlib
	mkdir -p riscv-fesvr/build
	cd riscv-fesvr/build;\
	../configure $(fesvr-co);\
	make $(fesvr-mk);\
	make install;\
	cd $(ROOT)

isa-sim: install-dir gnu-toolchain-newlib fesvr
	mkdir -p riscv-isa-sim/build
	cd riscv-isa-sim/build;\
	../configure $(isa-sim-co);\
	make $(isa-sim-mk);\
	make install;\
	cd $(ROOT)

tests: install-dir gnu-toolchain-newlib
	mkdir -p riscv-tests/build
	cd riscv-tests/build;\
	autoconf;\
	../configure $(tests-co);\
	make $(tests-mk);\
	make install;\
	cd $(ROOT)

pk: install-dir gnu-toolchain-newlib
	mkdir -p riscv-pk/build
	cd riscv-pk/build;\
	../configure $(pk-co);\
	make $(pk-mk);\
	make install;\
	cd $(ROOT)

all: gnu-toolchain-newlib gnu-toolchain-libc fesvr isa-sim tests pk

linux: gnu-toolchain-newlib gnu-toolchain-libc fesvr
	RISCV=$(RISCV) make -C ariane-linux bbl


clean:
	rm -rf install riscv-fesvr/build riscv-isa-sim/build riscv-gnu-toolchain/build riscv-tests/build riscv-pk/build


help:
	@echo "usage: $(MAKE) [RISCV='<install/here>'] [<tool>] [<tool>='--<flag> ...'] ..."
	@echo ""
	@echo "install [tool] to \$$RISCV with compiler <flag>'s"
	@echo ""
	@echo "where tool can be any one of:"
	@echo ""
	@echo "    fesvr isa-sim gnu-toolchain tests pk"
	@echo ""
	@echo "defaults:"
	@echo "    RISCV='$(DEST)'"
