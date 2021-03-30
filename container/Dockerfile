 FROM ubuntu:18.04

 RUN apt-get update && \
     apt-get install -y \
            autoconf \
            automake \
            autotools-dev \
            curl \
            libmpc-dev \
            libmpfr-dev \
            libgmp-dev \
            libusb-1.0-0-dev \
            gawk \
            build-essential \
            bison \
            flex \
            texinfo \
            gperf \
            libtool \
            patchutils \
            bc \
            zlib1g-dev \
            device-tree-compiler \
            pkg-config \
            libexpat-dev \
            wget \
            cpio \
            python3 \
            unzip \
            rsync \
            git && \
    apt-get clean ; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

