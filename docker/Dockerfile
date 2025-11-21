# Use Ubuntu 20.04 as base image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Update and install basic packages
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    python3 \
    python3-pip \
    python3-dev \
    curl \
    wget \
    unzip \
    locales \
    sudo \
    gawk \
    git-core \
    diffstat \
    texinfo \
    gcc-multilib \
    chrpath \
    socat \
    cpio \
    python3-pexpect \
    xz-utils \
    debianutils \
    iputils-ping \
    python3-git \
    python3-jinja2 \
    libegl1-mesa \
    libsdl1.2-dev \
    xterm \
    python3-subunit \
    mesa-common-dev \
    lz4 \
    zstd \
    libncurses5-dev \
    libtinfo5 \
    file \
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Install Kas (pinned version)
RUN pip3 install kas==4.3.2

# Create a user for building
RUN useradd -m -s /bin/bash yocto && echo "yocto:yocto" | chpasswd && usermod -aG sudo yocto

# Allow sudo without password for yocto user
RUN echo "yocto ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER yocto
WORKDIR /home/yocto

# Set the default command
CMD ["/bin/bash"]
