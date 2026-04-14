FROM ubuntu:24.04 AS build

ARG BOARD
ARG XLEN

RUN apt-get update && apt-get install -y make gcc g++ file git wget cpio unzip rsync bc bzip2 autoconf libssl-dev libgnutls28-dev openssh-client
COPY blobs /src/blobs
COPY br2-ext-tree /src/br2-ext-tree
COPY buildroot /src/buildroot
COPY configs /src/configs
COPY patches /src/patches
COPY rootfs /src/rootfs
COPY fitImage.its.template Makefile permission_table.txt post_build.sh post_image.sh /src/
WORKDIR /src
RUN make XLEN=$XLEN BOARD=$BOARD

FROM scratch

ARG BOARD
ARG XLEN

COPY --from=build /src/install${XLEN}_${BOARD}/sdcard.img /install${XLEN}_${BOARD}/sdcard.img
