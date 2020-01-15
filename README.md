# Ariane SDK

This repository is used to create a bootable linux image for the [ariane core](https://github.com/pulp-platform/ariane). It contains some small modifications to the official [riscv-pk](https://github.com/riscv/riscv-pk).

## Requirements

You require the following crosscompilation toolchains for RISC-V: riscv64-unknown-elf-gcc and riscv64-unknown-linux-gnu. These can be optained from the official [riscv-gnu-toolchain](https://github.com/riscv/riscv-gnu-toolchain) or by using [crosstool-ng](https://crosstool-ng.github.io/):

```console
$ ct-ng list-samples
$ ct-ng riscv64-unknown-elf # or riscv64-unknown-linux-gnu
$ ct-ng build
```

If you want you can use your own local toolchain from [riscv-gnu-toolchain](https://github.com/riscv/riscv-gnu-toolchain) by changing the buildroot config in [configs/buildroot_defconfig](configs/buildroot_defconfig).

## Linux
You can build a compatible linux image with bbl that boots linux on the ariane fpga mapping:
```console
$ make vmlinux # make only the vmlinux image, outputs a vmlinux file in the top directory
$ make bbl.bin # generate the entire bootable image, outputs bbl and bbl.bin
```

### Booting from an SD card
The bootloader of ariane requires a GPT partition table so you first have to create one with gdisk.

```console
$ sudo fdisk -l # search for the corresponding disk label (e.g. /dev/sdb)
$ sudo sgdisk --clear --new=1:2048:67583 --new=2 --typecode=1:3000 --typecode=2:8300 /dev/sdb # create a new gpt partition table and two partitions: 1st partition: 32mb (ONIE boot), second partition: rest (Linux root)
```

Now you have to compile the linux kernel:
```console
$ make bbl.bin # generate the entire bootable image
```

Then the bbl+linux kernel image can get copied to the sd card with `dd`. __Careful:__  use the same disk label that you found before with `fdisk -l` but with a 1 in the end, e.g. `/dev/sdb` -> `/dev/sdb1`.
```console
$ sudo dd if=bbl.bin of=/dev/sdb1 status=progress oflag=sync bs=1M
```

## Ethernet SSH
This patch incorporates an overlay to overcome the painful delay in generating public/private key pairs on the target
(which happens every time because the root filing system is volatile). Do not use these keys on more than one device.
Likewise it also incorporates a script (rootfs/etc/init.d/S40fixup) which replaces the MAC address with a valid Digilent
value. This should be replaced by the unique value on the back of the Genesys2 board if more than one device is used on
the same VLAN. Needless to say both of these values would need regenerating for anything other than development use.

