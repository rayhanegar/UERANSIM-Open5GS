# Dockerfile for Open5GS HSS (Home Subscriber Server)
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

# Install Open5GS HSS (Home Subscriber Server) and its dependencies
RUN apt-get install -y --no-install-recommends \
        open5gs-hss \
        open5gs-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /var/log/open5gs \
    && mkdir -p /etc/open5gs/tls \
    && mkdir -p /var/run/open5gs

# Copy configuration file (will be mounted as volume in production)
# Default configuration can be overridden by mounting a custom hss.yaml
COPY hss.yaml /etc/open5gs/hss.yaml

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
if [ -f /etc/open5gs/custom/hss.yaml ]; then\n\
    echo "Using custom configuration from /etc/open5gs/custom/hss.yaml"\n\
    cp /etc/open5gs/custom/hss.yaml /etc/open5gs/hss.yaml\n\
fi\n\
\n\
echo "Starting Open5GS HSS (Home Subscriber Server)..."\n\
echo "Configuration file: /etc/open5gs/hss.yaml"\n\
\n\
# Start HSS (Home Subscriber Server) in foreground\n\
/usr/bin/open5gs-hssd -c /etc/open5gs/hss.yaml &\n\
\n\
child=$!\n\
wait "$child"\n\
' > /usr/local/bin/start-hss.sh && \
    chmod +x /usr/local/bin/start-hss.sh

# Expose HSS (Home Subscriber Server) ports
# Diameter (S6a/Cx interface) - TCP/SCTP
EXPOSE 3868/tcp
EXPOSE 3868/sctp
# Metrics
EXPOSE 9090/tcp

# Set working directory
WORKDIR /etc/open5gs

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
    CMD pgrep open5gs-hssd > /dev/null || exit 1

# Run HSS (Home Subscriber Server)
ENTRYPOINT ["/usr/local/bin/start-hss.sh"]
