# CVA6 SDK

This repository houses a set of RISCV tools for the [CVA6 core](https://github.com/openhwgroup/cva6).
Most importantly, it **does not contain openOCD**.

As of now, the SDK has been designed and tested for the **Digilent Genesys 2** and **Agilex 7** FPGA boards. To implement and test SDK for other boards in this repository, you can volunteer to create and drive a new project at the OpenHW Group.

## Quickstart

Below are the packages required to build the Linux image for CVA6.

Ubuntu 24.04:
```console
$ sudo apt-get install make gcc g++ file git wget cpio unzip rsync bc bzip2 autoconf libssl-dev libgnutls28-dev
```

Fedora 42:
```console
$ sudo dnf install make gcc g++ perl which awk git bc rsync cpio wget patch openssl-devel openssl-devel-engine gnutls-devel
```

Both the CVA6 chip and this SDK are compiled for 64-bit by default.
You can select the XLEN (i.e., 32- or 64-bit) by setting the `XLEN` variable on `make`.
The target board can be specified with `BOARD=` which is `genesys2` by default.
Compile the image with:

```console
$ git submodule update --init --recursive
$ make  # or `make XLEN=32 BOARD=agilex7` for 32-bit/agilex7
```

This builds a RISC-V toolchain, OpenSBI, u-boot including a corresponding device tree, the Linux kernel, and the initramfs including the rootfs.

By default, the final image is generated at `install<XLEN>_<BOARD>/sdcard.img`.
To change the location, set the `OUTPUT` variable in the `make` command like `make OUTPUT=build`.

## Flash to SD card

Assuming `XLEN=64` and `BOARD=genesys2`.

### Linux

```console
$ dd if=install64_genesys2/sdcard.img of=/dev/sd<device> status=progress oflag=sync bs=4M conv=sparse
```

Note that you need to change `<device>` to the actual device letter of your SD card.
Use the command `lsblk` or `fdisk -l` to find it.

### Windows

The final image file `install64_genesys2/sdcard.img` can be flashed to an SD card with [Rufus](https://rufus.ie).

## CVA6 compatibility

Tested with the following CVA6 configs:
- **32-bit**: `cv32a6_ima_sv32_fpga`
- **64-bit**: `cv64a6_imafdc_sv39`

## Repository content

- **./blobs/**: Contains pre-built binary files. For example, `altera-u-boot.itb`, which is a flattened image tree binary required by the Agilex7 board by its Arm processor. It was built from the offical [Altera repository](https://github.com/altera-fpga/u-boot-socfpga). Execute `buildroot/output/host/bin/mkimage -l blobs/altera-u-boot.itb` to list its content.
- **./br2-ext-tree/**: Extension tree for buildroot. This directory contains packages which are not part of the official buildroot package list.
- **./buildroot/**: The mainline buildroot repository without any custom changes. It is a git submodule.
- **./configs/**: Contains config files including `genimage.cfg` which defines the structure and content of the final image `sdcard.img`..
- **./patches/**: Contains patches used by buildroot to apply to software components. It includes the Linux driver for the [open-source Ethernet media access controller](https://github.com/lowRISC/ariane-ethernet) from lowRISC required for ethernet to work under Linux in the CVA6. And patches to add CVA6 support to U-Boot.
- **./rootfs/**: The filesystem overlay. Put files here if you want to use them on your target system. Contains key files to prevent them having to be generated on each boot. Explained in further detail below.
- **./Dockerfile**: Dockerfile to build the image. Explained in further detail below.
- **./fitImage.its.template**: This defines the content of the [Flat Image Tree (FIT)](https://docs.u-boot.org/en/stable/usage/fit/howto.html) used by U-Boot to package the boot components it is meant to read and launch. The FIT image is part of the `sdcard.img`.
- **./permission_table.txt**: Used by buildroot to set the permissions of custom files on the target. 
- **./post_image.sh**: Called by buildroot after all components have been built. It packages them into the final image `sdcard.img`.

## Structure of final image `sdcard.img` (for genesys2)

As defined in the files `configs/genesys2/genimage.cfg` and `fitImage.its.template`:

```
+----------------sdcard.img (from genimage.cfg) ---------------+
|                                                              |
|  +------------------+------------------------------------+   |
|  |  GPT Header &    |                                    |   |
|  |  Partition       |   ... GPT Partition Entries ...    |   |
|  |  Table           |                                    |   |
|  +------------------+------------------------------------+   |
|                                                              |
|  +--------------------------------------------------------+  |
|  |                 Partition 1 (raw)                      |  |
|  |  Contains:                                             |  |
|  |   - fw_payload.bin (OpenSBI + U-Boot)                  |  |
|  +--------------------------------------------------------+  |
|                                                              |
|  +--------------------------------------------------------+  |
|  |           Partition 2 (FAT filesystem)                 |  |
|  |  Contains:                                             |  |
|  |   - fitImage.itb (Kernel + DTB + Ramdisk)              |  |
|  |     as defined by fitImage.its.template                |  |
|  +--------------------------------------------------------+  |
|                                                              |
+--------------------------------------------------------------+
```

## Boot procedure

This project follows the common RISC-V boot procedure.

1. [BootROM](https://github.com/openhwgroup/cva6/tree/master/corev_apu/fpga/src/bootrom) (M-Mode). Loads 1st partition (OpenSBI with U-Boot as payload) from SD card into DRAM memory and executes it.
2. [OpenSBI](https://github.com/riscv-software-src/opensbi) (M-Mode). Stays in memory to provide M-mode services to S-Mode software later. U-Boot was also loaded in the previous step, so OpenSBI directly executes U-Boot.
3. [U-Boot](https://github.com/u-boot/u-boot) (S-Mode). Loads `fitImage.itb` from 2nd partition from SD card into DRAM memory. It then launches the Linux kernel while providing the addresses to the DTB and Ramdisk from the `fitimage.itb`. U-Boot is only resident in memory during the boot process.
4. [Linux Kernel](https://github.com/torvalds/linux) (S-Mode). Loads, decompresses and launches /sbin/init from Ramdisk.
5. User space applications (U-Mode)

## Run in QEMU

```sh
make XLEN=64 BOARD=qemu
buildroot/output/host/bin/qemu-system-riscv64 \
    -M virt -cpu rv64 -m 1G -nographic \
    -bios install64_qemu/fw_dynamic.bin \
    -initrd install64_qemu/rootfs.cpio \
    -kernel install64_qemu/Image \
    -append "rootwait root=/dev/ram ro"
```

It uses a simpler boot process that skips the U-Boot step.
Otherwise, a U-Boot configuration would need to be maintained, which allows U-Boot to run in a virtual environment but boot from an (emulated) SD card, as the FPGA version does.


## Using toolchain outside of the SDK

See [Using the generated toolchain outside Buildroot](https://buildroot.org/downloads/manual/using-buildroot-toolchain.txt) from the buildroot documentation to see how to do it.


## OpenOCD - Optional
If you really need and want to debug on an FPGA/ASIC target the installation instructions are [here](https://github.com/riscv-collab/riscv-openocd).

## Pre-generated SSH keys
The directory at `rootfs/etc/ssh` adds pre-generated public/private key pairs on the target to overcome the painful delay of generating it at boot-time
(which happens every time because the root file system is volatile). Do not use these keys on more than one device, and especially not in productive environments as the private keys are revealed in this directory.

## MAC address
Each Genesys 2 board stores a MAC address in a special designated storage area, also written on a sticker on its bottom side.
It would be nice to U-Boot read this MAC address, and apply it to the interface.
However, this requires board-specific code which U-Boot does not provide.

Instead, the target currently uses the default MAC address of the [lowRISC Ethernet adapter](https://github.com/lowRISC/ariane-ethernet) which is `23:01:00:89:07:02`.
If you plan to run multiple Genesys 2 boards on the same network, assign unique MAC addresses. For example, use an init script in the rootfs folder like `ip link set dev eth0 address 00:18:3E:...`.
This ensures each board has a different MAC address and avoids collisions.

# Docker Container

There is a Dockerfile to build the target image.
Note that the `buildroot` submodule needs to be initialized nevertheless.
The following command builds the `sdcard.img` and puts it into the `install64_genesys2` directory.

```console
$ sudo docker buildx build --build-arg XLEN=64 --build-arg BOARD=genesys2 -t cva6-sdk-build --output=. .
```
