# Dockerfile for Open5GS MME (Mobility Management Entity)
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

# Install Open5GS MME (Mobility Management Entity) and its dependencies
RUN apt-get install -y --no-install-recommends \
        open5gs-mme \
        open5gs-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /var/log/open5gs \
    && mkdir -p /etc/open5gs/tls \
    && mkdir -p /var/run/open5gs

# Copy configuration file (will be mounted as volume in production)
# Default configuration can be overridden by mounting a custom mme.yaml
COPY mme.yaml /etc/open5gs/mme.yaml

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
if [ -f /etc/open5gs/custom/mme.yaml ]; then\n\
    echo "Using custom configuration from /etc/open5gs/custom/mme.yaml"\n\
    cp /etc/open5gs/custom/mme.yaml /etc/open5gs/mme.yaml\n\
fi\n\
\n\
echo "Starting Open5GS MME (Mobility Management Entity)..."\n\
echo "Configuration file: /etc/open5gs/mme.yaml"\n\
\n\
# Start MME (Mobility Management Entity) in foreground\n\
/usr/bin/open5gs-mmed -c /etc/open5gs/mme.yaml &\n\
\n\
child=$!\n\
wait "$child"\n\
' > /usr/local/bin/start-mme.sh && \
    chmod +x /usr/local/bin/start-mme.sh

# Expose MME (Mobility Management Entity) ports
# S1AP (S1 interface) - SCTP
EXPOSE 36412/sctp
# GTP-C (S11 interface) - UDP
EXPOSE 2123/udp
# Diameter (S6a interface) - TCP/SCTP
EXPOSE 3868/tcp
EXPOSE 3868/sctp
# Metrics
EXPOSE 9090/tcp

# Set working directory
WORKDIR /etc/open5gs

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
    CMD pgrep open5gs-mmed > /dev/null || exit 1

# Run MME (Mobility Management Entity)
ENTRYPOINT ["/usr/local/bin/start-mme.sh"]
