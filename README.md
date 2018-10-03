# Ariane SDK

This repository houses a set of RISCV tools for the [ariane core](https://github.com/pulp-platform/ariane). It contains some small changes to the official [riscv-tools](https://github.com/riscv/riscv-tools). Most importantly it **does not contain openOCD**.

Included tools:
* [Spike](https://github.com/riscv/riscv-isa-sim/), the ISA simulator
* [riscv-tests](https://github.com/riscv/riscv-tests/), a battery of ISA-level tests
* [riscv-pk](https://github.com/riscv/riscv-pk/), which contains `bbl`, a boot loader for Linux and similar OS kernels, and `pk`, a proxy kernel that services system calls for a target-machine application by forwarding them to the host machine
* [riscv-fesvr](https://github.com/riscv/riscv-fesvr/), the host side of a simulation tether that services system calls on behalf of a target machine
* [riscv-gnu-toolchain](https://github.com/riscv/riscv-gnu-toolchain), the cross compilation toolchain for riscv targets

## Quickstart

Requirements Ubuntu:
```console
$ sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev libusb-1.0-0-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev device-tree-compiler pkg-config libexpat-dev
```

Requirements Fedora:
```console
$ sudo dnf install autoconf automake @development-tools curl dtc libmpc-devel mpfr-devel gmp-devel libusb-devel gawk gcc-c++ bison flex texinfo gperf libtool patchutils bc zlib-devel expat-devel
```

```console
$ git submodule update --init --recursive
$ export RISCV=/path/to/install/riscv/toolchain # default: ./install
$ make all
```

Add `$RISCV/bin` to your path in order to later make use of the installed tools.

## OpenOCD - Optional
If you really need and want to debug on an FPGA/ASIC target the installation instructions are [here](https://github.com/riscv/riscv-openocd). 