# Dockerfile for Open5GS PCRF (Policy and Charging Rules Function)
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
        libbson-1.0-0 libfreediameter-dev freediameter-extensions && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add Open5GS repository
RUN add-apt-repository ppa:open5gs/latest && \
    apt-get update

# Install Open5GS PCRF (Policy and Charging Rules Function) and its dependencies
RUN apt-get install -y --no-install-recommends \
        open5gs-pcrf \
        open5gs-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /var/log/open5gs \
    && mkdir -p /etc/open5gs/tls \
    && mkdir -p /var/run/open5gs

# Copy configuration file (will be mounted as volume in production)
# Default configuration can be overridden by mounting a custom pcrf.yaml
COPY pcrf.yaml /etc/open5gs/pcrf.yaml

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
if [ -f /etc/open5gs/custom/pcrf.yaml ]; then\n\
    echo "Using custom configuration from /etc/open5gs/custom/pcrf.yaml"\n\
    cp /etc/open5gs/custom/pcrf.yaml /etc/open5gs/pcrf.yaml\n\
fi\n\
\n\
echo "Starting Open5GS PCRF (Policy and Charging Rules Function)..."\n\
echo "Configuration file: /etc/open5gs/pcrf.yaml"\n\
\n\
# Start PCRF (Policy and Charging Rules Function) in foreground\n\
/usr/bin/open5gs-pcrfd -c /etc/open5gs/pcrf.yaml &\n\
\n\
child=$!\n\
wait "$child"\n\
' > /usr/local/bin/start-pcrf.sh && \
    chmod +x /usr/local/bin/start-pcrf.sh

# Expose PCRF (Policy and Charging Rules Function) ports
# Diameter (Gx/Rx interface) - TCP/SCTP
EXPOSE 3868/tcp
EXPOSE 3868/sctp
# Metrics
EXPOSE 9090/tcp

# Set working directory
WORKDIR /etc/open5gs

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
    CMD pgrep open5gs-pcrfd > /dev/null || exit 1

# Run PCRF (Policy and Charging Rules Function)
ENTRYPOINT ["/usr/local/bin/start-pcrf.sh"]
