FROM ubuntu:20.04

# -----------------------------------------------------------------------------
# Define Dockerfile arguments.
# -----------------------------------------------------------------------------
ARG TZ="Europe/Rome"
ARG GIT_REPO_URL="https://github.com/openhwgroup/cva6-sdk"
ARG GIT_REPO_COMMIT="0f605ac"
ARG CONTAINER_USER="user"

# -----------------------------------------------------------------------------
# Configure timezone.
# -----------------------------------------------------------------------------
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
RUN echo $TZ > /etc/timezone

# -----------------------------------------------------------------------------
# Install required packages.
# -----------------------------------------------------------------------------
RUN apt-get update
RUN apt-get install -y 		\
	vim 			\
	git			\
	autoconf 		\
        automake 		\
        autotools-dev 		\
        curl 			\
        libmpc-dev 		\
        libmpfr-dev 		\
        libgmp-dev 		\
        libusb-1.0-0-dev	\
        gawk 			\
        build-essential 	\
        bison 			\
        flex 			\
        texinfo 		\
        gperf 			\
        libtool 		\
        patchutils 		\
        bc 			\
        zlib1g-dev 		\
        device-tree-compiler 	\
        pkg-config 		\
        libexpat-dev		\
	wget			\
	cpio			\
	python			\
	unzip			\
	rsync			\
	libncurses-dev

# -----------------------------------------------------------------------------
# Create a new user.
# -----------------------------------------------------------------------------
RUN useradd -ms /bin/bash $CONTAINER_USER
RUN passwd -d $CONTAINER_USER
WORKDIR /home/$CONTAINER_USER
USER $CONTAINER_USER

# -----------------------------------------------------------------------------
# Download cva6-sdk and build the RISC-V toolchain.
# -----------------------------------------------------------------------------
ENV RISCV="/home/$CONTAINER_USER/.local/riscv"
ENV PATH="$PATH:$RISCV/bin"

RUN git clone $GIT_REPO_URL /home/$CONTAINER_USER/cva6-sdk
WORKDIR /home/$CONTAINER_USER/cva6-sdk
RUN git checkout $GIT_REPO_COMMIT
RUN git submodule update --init --recursive
RUN make all
WORKDIR /home/$CONTAINER_USER

