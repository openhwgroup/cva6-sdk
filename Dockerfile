FROM ubuntu:24.04 AS build

RUN apt-get update && apt-get install -y make gcc g++ file git wget cpio unzip rsync bc bzip2 autoconf libssl-dev libgnutls28-dev
COPY br2-ext-tree /src/br2-ext-tree
COPY buildroot /src/buildroot
COPY configs /src/configs
COPY patches /src/patches
COPY patches32 /src/patches32
COPY rootfs /src/rootfs
COPY genimage.cfg fitImage.its.template Makefile permission_table.txt post_image.sh /src/
WORKDIR /src
RUN make

FROM scratch
COPY --from=build /src/install64/sdcard.img /
