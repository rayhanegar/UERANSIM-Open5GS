# Dockerfile for Open5GS UDM (Unified Data Management)
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Update and install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        gnupg \
        wget \
        ca-certificates \
        netbase \
        iputils-ping \
        net-tools \
        iproute2 \
        iptables \
        tcpdump \
        vim \
        curl \
        libyaml-0-2 \
        libmicrohttpd12 \
        libtalloc2 \
        libsctp1 \
        libgnutls30 \
        libcurl4-gnutls-dev \
        libnghttp2-14 \
        libidn11 \
        libmongoc-1.0-0 \
        libbson-1.0-0  && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add Open5GS repository
RUN add-apt-repository ppa:open5gs/latest && \
    apt-get update

# Install Open5GS UDM (Unified Data Management) and its dependencies
RUN apt-get install -y --no-install-recommends \
        open5gs-udm \
        open5gs-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /var/log/open5gs \
    && mkdir -p /etc/open5gs/tls \
    && mkdir -p /var/run/open5gs

# Copy configuration file (will be mounted as volume in production)
# Default configuration can be overridden by mounting a custom udm.yaml
COPY udm.yaml /etc/open5gs/udm.yaml

# Create a startup script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Function to handle signals\n\
_term() {\n\
  echo "Caught SIGTERM signal!"\n\
  kill -TERM "$child" 2>/dev/null\n\
}\n\
\n\
trap _term SIGTERM SIGINT\n\
\n\
# Check if custom config exists\n\
if [ -f /etc/open5gs/custom/udm.yaml ]; then\n\
    echo "Using custom configuration from /etc/open5gs/custom/udm.yaml"\n\
    cp /etc/open5gs/custom/udm.yaml /etc/open5gs/udm.yaml\n\
fi\n\
\n\
echo "Starting Open5GS UDM (Unified Data Management)..."\n\
echo "Configuration file: /etc/open5gs/udm.yaml"\n\
\n\
# Start UDM (Unified Data Management) in foreground\n\
/usr/bin/open5gs-udmd -c /etc/open5gs/udm.yaml &\n\
\n\
child=$!\n\
wait "$child"\n\
' > /usr/local/bin/start-udm.sh && \
    chmod +x /usr/local/bin/start-udm.sh

# Expose UDM (Unified Data Management) ports
# SBI (Service Based Interface) - HTTP/2
EXPOSE 7777/tcp

# Set working directory
WORKDIR /etc/open5gs

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
    CMD pgrep open5gs-udmd > /dev/null || exit 1

# Run UDM (Unified Data Management)
ENTRYPOINT ["/usr/local/bin/start-udm.sh"]
