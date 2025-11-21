# Dockerfile for SDK environment
# Derived from the base master-builder image

ARG BASE_IMAGE=master-builder:latest
FROM ${BASE_IMAGE}

# Switch to root to install SDK
USER root

# Create directory for SDK installation
RUN mkdir -p /opt/sdk

# Copy SDK installer script
COPY tmp/sdk-installer.sh /tmp/sdk-installer.sh

# Install SDK if installer exists
RUN if [ -f /tmp/sdk-installer.sh ]; then \
    chmod +x /tmp/sdk-installer.sh && \
    /tmp/sdk-installer.sh -d /opt/sdk -y && \
    rm -f /tmp/sdk-installer.sh; \
    fi

# Set up SDK environment in user's bashrc
RUN if [ -d /opt/sdk ]; then \
    echo 'if [ -f /opt/sdk/environment-setup-* ]; then source /opt/sdk/environment-setup-*; fi' >> /home/yocto/.bashrc; \
    fi

# Switch back to yocto user
USER yocto
WORKDIR /home/yocto

# Default command
CMD ["/bin/bash"]
