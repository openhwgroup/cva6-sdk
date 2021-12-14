# CVA6 SDK

This repository houses a set of RISCV tools for the [CVA6 core](https://github.com/openhwgroup/cva6). Most importantly it **does not contain openOCD**.

Included tools:
* [Spike](https://github.com/riscv/riscv-isa-sim/), the ISA simulator
* [riscv-tests](https://github.com/riscv/riscv-tests/), a battery of ISA-level tests
* [riscv-fesvr](https://github.com/riscv/riscv-fesvr/), the host side of a simulation tether that services system calls on behalf of a target machine
* [u-boot](https://github.com/openhwgroup/u-boot/)
* [opensbi](https://github.com/riscv/opensbi/), the open-source reference implementation of the RISC-V Supervisor Binary Interface (SBI)

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
Then compile the Linux images with

```console
$ git submodule update --init --recursive
$ make images
```

## Environment Variables

If you want to cross compile other projects for this target you can add `buildroot/output/host/bin/` to your path in order to later make use of the installed tools after compiling them with :

```bash
$ make all
```

## Linux
You can also build a compatible Linux image that boots Linux on the CVA6 fpga mapping:
```bash
$ make vmlinux # make only the elf Linux image
$ make uImage.bin # generate the Linux image with the u-boot wrapper
$ make fw_payload.bin # generate the OpenSBI + U-Boot payload
```

Or you can build everything directly with:

```bash
$ make images # generates all images and save them in install$(XLEN)
```

## Spike
You can test your image on spike 
First, build spike with:

```bash
$ make isa-sim
```

Build the OpenSBI firmware with the Linux payload for the Spike platform:

```bash
$ make spike_payload
```

You can now launch Spike with OpenSBI + Linux

```bash
$ install$(XLEN)/bin/spike install$(XLEN)/spike_fw_payload.elf
```

Spike allows trace logging

```bash
$ install$(XLEN)/bin/spike --log-commits install$(XLEN)/spike_fw_payload.elf 2> trace.log.commits
```

### Booting from an SD card

First compile the SBI firmware and the Linux image:

```bash
$ make images
```

The flash-sdcard Makefile recipe handle the creation of the GPT partition table and the flashing of fw\_payload.bin and uImage at there correct offset. **Be careful to set the correct SDDEVICE.**

```bash
$ sudo -E make flash-sdcard SDDEVICE=/dev/sdb
```

## OS X

Similar steps as above but flashing is sligthly different. Get `sgdisk` using `homebrew`.

```
$ brew install gptfdisk
$ sudo -E make flash-sdcard SDDEVICE=/dev/sdb
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
