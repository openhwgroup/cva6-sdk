# Ariane SDK

This repository houses a set of RISCV tools for the [ariane core](https://github.com/pulp-platform/ariane). It contains some small modifications to the official [riscv-tools](https://github.com/riscv/riscv-tools). Most importantly it **does not contain openOCD**.

Included tools:
* [Spike](https://github.com/riscv/riscv-isa-sim/), the ISA simulator
* [riscv-tests](https://github.com/riscv/riscv-tests/), a battery of ISA-level tests
* [riscv-pk](https://github.com/riscv/riscv-pk/), which contains `bbl`, a boot loader for Linux and similar OS kernels, and `pk`, a proxy kernel that services system calls for a target-machine application by forwarding them to the host machine
* [riscv-fesvr](https://github.com/riscv/riscv-fesvr/), the host side of a simulation tether that services system calls on behalf of a target machine

## Quickstart

Requirements Ubuntu:
```console
$ sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev libusb-1.0-0-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev device-tree-compiler pkg-config libexpat-dev
```

Requirements Fedora:
```console
$ sudo dnf install autoconf automake @development-tools curl dtc libmpc-devel mpfr-devel gmp-devel libusb-devel gawk gcc-c++ bison flex texinfo gperf libtool patchutils bc zlib-devel expat-devel
```
You can select the XLEN by setting it in the Makefile.
Then compile the images with

```console
$ git submodule update --init --recursive
$ export RISCV=/path/to/install/riscv/toolchain # default: ./install$(XLEN)
$ make images
```

## Environment Variables

If you want to cross compile other projects for this target you can add `$RISCV/bin` to your path in order to later make use of the installed tools and permanently export `$RISCV`.

Example for `.bashrc` or `.zshrc`:
```bash
$ export RISCV=/opt/riscv
$ export PATH=$PATH:$RISCV/bin
```

## Linux
You can also build a compatible linux image with bbl that boots linux on the ariane fpga mapping:
```bash
$ make vmlinux # make only the vmlinux image
# outputs a vmlinux file in the top directory
$ make bbl.bin # generate the entire bootable image
# outputs bbl and bbl.bin
$ make images # generates all images and save them in $(RISCV)
# outputs $(RISCV)/vmlinux, $(RISCV)/bbl and $(RISCV)/bbl.bin
```

## Spike
You can test your image on spike 
```bash
$ $(RISCV)/bin/spike bbl 2> /dev/null
```
Spike allows trace logging
```bash
$ $(RISCV)/bin/spike --log-commits bbl 2> trace.log.commits
```

### Booting from an SD card
The bootloader of ariane requires a GPT partition table so you first have to create one with gdisk.

```bash
$ sudo fdisk -l # search for the corresponding disk label (e.g. /dev/sdb)
$ sudo sgdisk --clear --new=1:2048:67583 --new=2 --typecode=1:3000 --typecode=2:8300 /dev/sdb # create a new gpt partition table and two partitions: 1st partition: 32mb (ONIE boot), second partition: rest (Linux root)
```

Now you have to compile the linux kernel:
```bash
$ make bbl.bin # generate the entire bootable image
```

Then the bbl+linux kernel image can get copied to the sd card with `dd`. __Careful:__  use the same disk label that you found before with `fdisk -l` but with a 1 in the end, e.g. `/dev/sdb` -> `/dev/sdb1`.
```bash
$ sudo dd if=bbl.bin of=/dev/sdb1 status=progress oflag=sync bs=1M
```

## OS X

Similar steps as above but flashing is slgithly different. Get `sgdisk` using `homebrew`.

```
$ brew install gptfdisk
$ sudo sgdisk --clear -g --new=1:2048:67583 --new=2 --typecode=1:3000 --typecode=2:8300 /dev/disk2
$ sudo dd if=bbl.bin of=/dev/disk2s1  bs=1m
```

## OpenOCD - Optional
If you really need and want to debug on an FPGA/ASIC target the installation instructions are [here](https://github.com/riscv/riscv-openocd).

## Ethernet SSH
This patch incorporates an overlay to overcome the painful delay in generating public/private key pairs on the target
(which happens every time because the root filing system is volatile). Do not use these keys on more than one device.
Likewise it also incorporates a script (rootfs/etc/init.d/S40fixup) which replaces the MAC address with a valid Digilent
value. This should be replaced by the unique value on the back of the Genesys2 board if more than one device is used on
the same VLAN. Needless to say both of these values would need regenerating for anything other than development use.

# Docker Container

There is a pretty basic Docker container you can use to get a stable build environment to build the image.

```
$ cd container
$ sudo docker build -t ghcr.io/pulp-platform/ariane-sdk -f Dockerfile .
```

And build the image:
```
$ cd ..
$ sudo docker run -it -v `pwd`:/repo -w /repo -u $(id -u ${USER}):$(id -g ${USER}) ghcr.io/pulp-platform/ariane-sdk
```
