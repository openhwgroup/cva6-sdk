# CVA6 SDK

This repository houses a set of RISCV tools for the [CVA6 core](https://github.com/openhwgroup/cva6).
Most importantly, it **does not contain openOCD**.

As of now, the SDK has been designed and tested for the **Digilent Genesys 2** FPGA board. To implement and test SDK for other boards in this repository, you can volunteer to create and drive a new project at the OpenHW Group.

## Quickstart

Below are the packages required to build and flash the Linux image for CVA6 on a Genesys 2 board.

Ubuntu (tested on 24.04):
```console
$ sudo apt-get install make gcc g++ file git wget cpio unzip rsync bc bzip2 autoconf libssl-dev libgnutls28-dev
```

Fedora (tested on 42):
```console
$ sudo dnf install make gcc g++ perl which awk git bc rsync cpio wget patch openssl-devel openssl-devel-engine gnutls-devel
```

Both the CVA6 chip and this SDK are compiled for 64-bit by default.
You can select the XLEN (i.e., 32- or 64-bit) by setting the XLEN variable on `make`.
Compile the image with:

```console
$ git submodule update --init --recursive
$ make  # or `make XLEN=32` for 32-bit
```

This builds a RISC-V toolchain, OpenSBI, u-boot including a corresponding device tree, the Linux kernel, and the initramfs including the rootfs.

By default, the final image is generated at `install<XLEN>/sdcard.img`.
To change the location, set the `OUTPUT` variable in the `make` command like `make OUTPUT=build`.

## Flash to SD card

```console
$ dd if=install64/sdcard.img of=/dev/sd<device> status=progress oflag=sync bs=4M conv=sparse
```

Note that you need to change `<device>` to the actual device letter.
You can use `lsblk` or `fdisk -l` to figure out the path to your SD card.

## CVA6 compatibility

Tested with the following CVA6 configs:
- **32-bit**: `cv32a6_ima_sv32_fpga`
- **64-bit**: `cv64a6_imafdc_sv39`

## Repository content

- **./br2-ext-tree/**: Extension tree for buildroot. This directory contains packages which are not part of the official buildroot package list.
- **./buildroot/**: The mainline buildroot repository without any custom changes. It is a git submodule.
- **./configs/**: Contains relevant config files.
- **./linux_patch/**: Contains patches for the Linux kernel which are applied by buildroot before building it. Currently, it only contains the Ethernet driver for the [open-source Ethernet media access controller](https://github.com/lowRISC/ariane-ethernet) by lowRISC. This driver is not included in the Linux mainline. Without it, ethernet will not work with the stock CVA6.
- **./rootfs/**: The filesystem overlay. Put files here if you want to use them on your RISC-V system.
- **./Dockerfile**: Dockerfile to build the target image. Explained in further detail below.
- **./genimage.cfg**: This defines the structure and content of the final image `sdcard.img`.
- **./image.its.template**: This defines the content of the [Flat Image Tree (FIT)](https://docs.u-boot.org/en/stable/usage/fit/howto.html) used by u-boot to package the boot components it is meant to read and launch. The FIT image is part of `sdcard.img`.
- **./permission_table.txt**: Used by buildroot to set the permissions of custom files for the target. 
- **./post_image.sh**: Called by buildroot after all components have been built. It packages them into the final image `sdcard.img`.

We use a custom U-Boot repository that includes required changes.
Its URL is defined in the `buildroot/buildroot*_defconfig` file under the `BR2_TARGET_UBOOT_CUSTOM_REPO_URL` variable.

## Using toolchain outside of the SDK

See [Using the generated toolchain outside Buildroot](https://buildroot.org/downloads/manual/using-buildroot-toolchain.txt) from the buildroot documentation to see how to do it.


## OpenOCD - Optional
If you really need and want to debug on an FPGA/ASIC target the installation instructions are [here](https://github.com/riscv-collab/riscv-openocd).

## Pre-generated SSH keys
The directory at `rootfs/etc/ssh` adds pre-generated public/private key pairs on the target to overcome the painful delay of generating it at boot-time
(which happens every time because the root filing system is volatile). Do not use these keys on more than one device, and especially not in productive environments as the private keys are revealed in this directory.

## MAC address
Each Genesys 2 board stores a MAC address in a special designated storage area, also written on a sticker on its bottom side.
However, neither the Linux kernel nor u-boot supports reading it from the Genesys 2 board as far as we are aware.
Even though it is possible, theoretically.
The [Genesys 2 Reference Manual](https://digilent.com/reference/programmable-logic/genesys-2/reference-manual) says:
>To this end the Genesys 2 comes with a MAC address pre-programmed in a special one-time programmable region (OTP Region 1) of the Quad-SPI Flash6. This unique identifier can be read with the OTP Read command (0x4B).

Instead, the target currently uses the default MAC address by the [lowRISC Ethernet adapter](https://github.com/lowRISC/ariane-ethernet) which is `23:01:00:89:07:02`.
If you plan to run multiple Genesys 2 boards on the same network, assign unique MAC addresses. For example, use an init script in the rootfs folder like `ip link set dev eth0 address 00:18:3E:...`.
This ensures each board has a different MAC address and avoids collisions.
Note that the iproute2 package (which contains the `ip` binary) from buildroot is disabled by default.
Our defconfig in **./configs/** enables it, however.
Otherwise, you might want to use the deprecated `ifconfig` command which is enabled by default in buildroot and required anyways by udhcpc which we use as the DHCP client.

# Docker Container

There is a Dockerfile to build the target image.
The following command builds the `sdcard.img` and puts it into the `build/` directory.

```console
$ sudo docker buildx build -t cva6-sdk-build --output=build .
```
