#!/bin/bash

# Function to create/update Dockerfile for a specific NF
create_dockerfile() {
    local NF_NAME=$1
    local NF_UPPER=$2
    local NF_DAEMON=$3
    local PORTS=$4
    local EXTRA_DEPS=$5
    local EXTRA_SETUP=$6
    
    cat > "${NF_NAME}/Dockerfile" << EOF
# Dockerfile for Open5GS ${NF_UPPER}
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Update and install necessary packages
RUN apt-get update && \\
    apt-get install -y --no-install-recommends \\
        software-properties-common \\
        gnupg \\
        wget \\
        ca-certificates \\
        netbase \\
        iputils-ping \\
        net-tools \\
        iproute2 \\
        iptables \\
        tcpdump \\
        vim \\
        curl \\
        libyaml-0-2 \\
        libmicrohttpd12 \\
        libtalloc2 \\
        libsctp1 \\
        libgnutls30 \\
        libcurl4-gnutls-dev \\
        libnghttp2-14 \\
        libidn11 \\
        libmongoc-1.0-0 \\
        libbson-1.0-0 ${EXTRA_DEPS} && \\
    apt-get clean && \\
    rm -rf /var/lib/apt/lists/*

# Add Open5GS repository
RUN add-apt-repository ppa:open5gs/latest && \\
    apt-get update

# Install Open5GS ${NF_UPPER} and its dependencies
RUN apt-get install -y --no-install-recommends \\
        open5gs-${NF_NAME} \\
        open5gs-common && \\
    apt-get clean && \\
    rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /var/log/open5gs \\
    && mkdir -p /etc/open5gs/tls \\
    && mkdir -p /var/run/open5gs

# Copy configuration file (will be mounted as volume in production)
# Default configuration can be overridden by mounting a custom ${NF_NAME}.yaml
COPY ${NF_NAME}.yaml /etc/open5gs/${NF_NAME}.yaml

# Create a startup script
RUN echo '#!/bin/bash\\n\\
set -e\\n\\
\\n\\
# Function to handle signals\\n\\
_term() {\\n\\
  echo "Caught SIGTERM signal!"\\n\\
  kill -TERM "\$child" 2>/dev/null\\n\\
}\\n\\
\\n\\
trap _term SIGTERM SIGINT\\n\\
\\n\\
# Check if custom config exists\\n\\
if [ -f /etc/open5gs/custom/${NF_NAME}.yaml ]; then\\n\\
    echo "Using custom configuration from /etc/open5gs/custom/${NF_NAME}.yaml"\\n\\
    cp /etc/open5gs/custom/${NF_NAME}.yaml /etc/open5gs/${NF_NAME}.yaml\\n\\
fi\\n\\
\\n\\
echo "Starting Open5GS ${NF_UPPER}..."\\n\\
echo "Configuration file: /etc/open5gs/${NF_NAME}.yaml"\\n\\
${EXTRA_SETUP}\\n\\
# Start ${NF_UPPER} in foreground\\n\\
/usr/bin/open5gs-${NF_DAEMON} -c /etc/open5gs/${NF_NAME}.yaml &\\n\\
\\n\\
child=\$!\\n\\
wait "\$child"\\n\\
' > /usr/local/bin/start-${NF_NAME}.sh && \\
    chmod +x /usr/local/bin/start-${NF_NAME}.sh

# Expose ${NF_UPPER} ports
${PORTS}

# Set working directory
WORKDIR /etc/open5gs

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \\
    CMD pgrep open5gs-${NF_DAEMON} > /dev/null || exit 1

# Run ${NF_UPPER}
ENTRYPOINT ["/usr/local/bin/start-${NF_NAME}.sh"]
EOF
}

# AUSF
create_dockerfile "ausf" "AUSF (Authentication Server Function)" "ausfd" \
"# SBI (Service Based Interface) - HTTP/2
EXPOSE 7777/tcp" "" ""

# UDM
create_dockerfile "udm" "UDM (Unified Data Management)" "udmd" \
"# SBI (Service Based Interface) - HTTP/2
EXPOSE 7777/tcp" "" ""

# UDR
create_dockerfile "udr" "UDR (Unified Data Repository)" "udrd" \
"# SBI (Service Based Interface) - HTTP/2
EXPOSE 7777/tcp" "" ""

# PCF
create_dockerfile "pcf" "PCF (Policy Control Function)" "pcfd" \
"# SBI (Service Based Interface) - HTTP/2
EXPOSE 7777/tcp
# Metrics
EXPOSE 9090/tcp" "" ""

# NSSF
create_dockerfile "nssf" "NSSF (Network Slice Selection Function)" "nssfd" \
"# SBI (Service Based Interface) - HTTP/2
EXPOSE 7777/tcp" "" ""

# BSF
create_dockerfile "bsf" "BSF (Binding Support Function)" "bsfd" \
"# SBI (Service Based Interface) - HTTP/2
EXPOSE 7777/tcp" "" ""

# SCP
create_dockerfile "scp" "SCP (Service Communication Proxy)" "scpd" \
"# SBI (Service Based Interface) - HTTP/2
EXPOSE 7777/tcp" "" ""

# For 4G/EPC components, we need FreeDiameter
FREEDIAMETER_DEPS="libfreediameter-dev freediameter-extensions"

# MME
create_dockerfile "mme" "MME (Mobility Management Entity)" "mmed" \
"# S1AP (S1 interface) - SCTP
EXPOSE 36412/sctp
# GTP-C (S11 interface) - UDP
EXPOSE 2123/udp
# Diameter (S6a interface) - TCP/SCTP
EXPOSE 3868/tcp
EXPOSE 3868/sctp
# Metrics
EXPOSE 9090/tcp" "$FREEDIAMETER_DEPS" ""

# SGW-C
create_dockerfile "sgwc" "SGW-C (Serving Gateway Control Plane)" "sgwcd" \
"# GTP-C (S11/S5 interface) - UDP
EXPOSE 2123/udp
# PFCP (Sxa interface) - UDP
EXPOSE 8805/udp" "" ""

# SGW-U
create_dockerfile "sgwu" "SGW-U (Serving Gateway User Plane)" "sgwud" \
"# GTP-U (S1-U/S5-U interface) - UDP
EXPOSE 2152/udp
# PFCP (Sxa interface) - UDP
EXPOSE 8805/udp" "" ""

# HSS
create_dockerfile "hss" "HSS (Home Subscriber Server)" "hssd" \
"# Diameter (S6a/Cx interface) - TCP/SCTP
EXPOSE 3868/tcp
EXPOSE 3868/sctp
# Metrics
EXPOSE 9090/tcp" "$FREEDIAMETER_DEPS" ""

# PCRF
create_dockerfile "pcrf" "PCRF (Policy and Charging Rules Function)" "pcrfd" \
"# Diameter (Gx/Rx interface) - TCP/SCTP
EXPOSE 3868/tcp
EXPOSE 3868/sctp
# Metrics
EXPOSE 9090/tcp" "$FREEDIAMETER_DEPS" ""

echo "All Dockerfiles have been updated with correct ports!"