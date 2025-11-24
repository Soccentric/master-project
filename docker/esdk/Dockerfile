# Dockerfile for eSDK environment
# Derived from the base master-builder image

ARG BASE_IMAGE=master-builder:latest
FROM ${BASE_IMAGE}

# Switch to root to install eSDK
USER root

# Create directory for eSDK installation
RUN mkdir -p /opt/esdk

# Copy eSDK installer script
COPY tmp/esdk-installer.sh /tmp/esdk-installer.sh

# Install eSDK if installer exists
RUN if [ -f /tmp/esdk-installer.sh ]; then \
    chmod +x /tmp/esdk-installer.sh && \
    /tmp/esdk-installer.sh -d /opt/esdk -y && \
    rm -f /tmp/esdk-installer.sh; \
    fi

# Set up eSDK environment in user's bashrc
RUN if [ -d /opt/esdk ]; then \
    echo 'if [ -f /opt/esdk/environment-setup-* ]; then source /opt/esdk/environment-setup-*; fi' >> /home/yocto/.bashrc; \
    fi

# Switch back to yocto user
USER yocto
WORKDIR /home/yocto

# Default command
CMD ["/bin/bash"]
