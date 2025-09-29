# Dockerfile for Open5GS UPF (User Plane Function)
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

# Install Open5GS UPF and its dependencies
RUN apt-get install -y --no-install-recommends \
        open5gs-upf \
        open5gs-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /var/log/open5gs \
    && mkdir -p /etc/open5gs/tls \
    && mkdir -p /var/run/open5gs

# Copy configuration file (will be mounted as volume in production)
# Default configuration can be overridden by mounting a custom upf.yaml
COPY upf.yaml /etc/open5gs/upf.yaml

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
if [ -f /etc/open5gs/custom/upf.yaml ]; then\n\
    echo "Using custom configuration from /etc/open5gs/custom/upf.yaml"\n\
    cp /etc/open5gs/custom/upf.yaml /etc/open5gs/upf.yaml\n\
fi\n\
\n\
echo "Starting Open5GS UPF..."\n\
echo "Configuration file: /etc/open5gs/upf.yaml"\n\
\n\
# Enable IP forwarding\n\
echo 1 > /proc/sys/net/ipv4/ip_forward\n\
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding\n\
\n\
# Create TUN device for UE traffic\n\
ip tuntap add name ogstun mode tun\n\
ip addr add 10.45.0.1/24 dev ogstun\n\
ip link set ogstun up\n\
ip tuntap add name ogstun1 mode tun\n\
ip addr add 10.45.1.1/24 dev ogstun1\n\
ip link set ogstun1 up\n\
ip tuntap add name ogstun2 mode tun\n\
ip addr add 10.45.2.1/24 dev ogstun2\n\
ip link set ogstun2 up\n\
\n\
# Setup NAT for UE traffic\n\
iptables -t nat -A POSTROUTING -s 10.45.0.0/24 ! -o ogstun -j MASQUERADE\n\
iptables -t nat -A POSTROUTING -s 10.45.1.0/24 ! -o ogstun1 -j MASQUERADE\n\
iptables -t nat -A POSTROUTING -s 10.45.2.0/24 ! -o ogstun2 -j MASQUERADE\n\
\n\
# Start UPF in foreground\n\
/usr/bin/open5gs-upfd -c /etc/open5gs/upf.yaml &
\n\
child=$!\n\
wait "$child"\n\
' > /usr/local/bin/start-upf.sh && \
    chmod +x /usr/local/bin/start-upf.sh

# Expose UPF ports
# PFCP (N4 interface) - UDP
EXPOSE 8805/udp
# GTP-U (N3 interface for gNB) - UDP
EXPOSE 2152/udp
# Alternative GTP-U port if needed
EXPOSE 2153/udp
# Metrics
EXPOSE 9090/tcp

# Set working directory
WORKDIR /etc/open5gs

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
    CMD pgrep open5gs-upfd > /dev/null || exit 1

# Run UPF
ENTRYPOINT ["/usr/local/bin/start-upf.sh"]