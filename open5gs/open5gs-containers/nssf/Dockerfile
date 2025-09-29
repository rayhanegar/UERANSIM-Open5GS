# Dockerfile for Open5GS AMF (Access and Mobility Management Function)
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install system dependencies and Open5GS nssf in a single layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common gnupg && \
    add-apt-repository ppa:open5gs/latest && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        open5gs-nssf \
        open5gs-common \
        ca-certificates \
        netbase && \
    mkdir -p /var/log/open5gs /etc/open5gs/tls /var/run/open5gs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create open5gs user and group (matching systemd service)
RUN groupadd -r open5gs && \
    useradd -r -g open5gs -d /var/lib/open5gs -s /usr/sbin/nologin open5gs && \
    chown -R open5gs:open5gs /var/log/open5gs /var/run/open5gs

# Copy nssf configuration from current directory as default
# This will be overridden by Docker Compose volume mount
COPY nssf.yaml /etc/open5gs/nssf.yaml

# Set proper ownership for configuration and log directories  
RUN chown -R open5gs:open5gs /etc/open5gs /var/log/open5gs

# Volumes for Docker Compose (logs will be mounted)
VOLUME ["/var/log/open5gs"]

# Expose nssf ports
# SBI (Service Based Interface) - HTTP/2  
EXPOSE 7777/tcp

# Set working directory
WORKDIR /etc/open5gs

# Switch to open5gs user (matching systemd service: User=open5gs Group=open5gs)
USER open5gs

# Health check with restart behavior similar to systemd (RestartSec=2)
HEALTHCHECK --interval=2s --timeout=5s --start-period=10s --retries=3 \
    CMD pgrep open5gs-nssfd > /dev/null || exit 1

# Run nssf daemon directly (matching systemd ExecStart)-
# Uses embedded nssf.yaml from current directory
# Equivalent to: ExecStart=/usr/bin/open5gs-nssfd -c /etc/open5gs/nssf.yaml
CMD ["/usr/bin/open5gs-nssfd", "-c", "/etc/open5gs/nssf.yaml"]