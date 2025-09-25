# Dockerfile for Open5GS AMF (Access and Mobility Management Function)
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
        libbson-1.0-0 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add Open5GS repository
RUN add-apt-repository ppa:open5gs/latest && \
    apt-get update

# Install Open5GS AMF and its dependencies
RUN apt-get install -y --no-install-recommends \
        open5gs-amf \
        open5gs-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /var/log/open5gs \
    && mkdir -p /etc/open5gs/tls \
    && mkdir -p /var/run/open5gs

# Copy configuration file (will be mounted as volume in production)
# Default configuration can be overridden by mounting a custom amf.yaml
COPY amf.yaml /etc/open5gs/amf.yaml

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
if [ -f /etc/open5gs/custom/amf.yaml ]; then\n\
    echo "Using custom configuration from /etc/open5gs/custom/amf.yaml"\n\
    cp /etc/open5gs/custom/amf.yaml /etc/open5gs/amf.yaml\n\
fi\n\
\n\
echo "Starting Open5GS AMF..."\n\
echo "Configuration file: /etc/open5gs/amf.yaml"\n\
\n\
# Start AMF in foreground\n\
/usr/bin/open5gs-amfd -c /etc/open5gs/amf.yaml &\n\
\n\
child=$!\n\
wait "$child"\n\
' > /usr/local/bin/start-amf.sh && \
    chmod +x /usr/local/bin/start-amf.sh

# Expose AMF ports
# NGAP (N2 interface) - SCTP
EXPOSE 38412/sctp
# SBI (Service Based Interface) - HTTP/2
EXPOSE 7777/tcp

# Set working directory
WORKDIR /etc/open5gs

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
    CMD pgrep open5gs-amfd > /dev/null || exit 1

# Run AMF
ENTRYPOINT ["/usr/local/bin/start-amf.sh"]