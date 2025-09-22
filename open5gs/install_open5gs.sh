#!/bin/bash

# Open5GS Installation and Configuration Script
# Version: 1.0
# Date: Sep 22, 2025
# Description: Complete automated installation and configuration of Open5GS 5G Core Network
#              with 3 network slices (eMBB, URLLC, mMTC) and UERANSIM integration support
#
# Usage: sudo ./install_open5gs.sh [--install|--configure|--launch|--all|--clean]

set -e  # Exit on any error

# Script configuration
SCRIPT_NAME="Open5GS 5G Core Network Installer"
VERSION="1.0"
AUTHOR="5G CNF Research Testbed"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Network configuration for 3 slices
SLICE_CONFIGS=(
    "1:embb.testbed:10.45.0.0/24:10.45.0.1:ogstun:eMBB"
    "2:urllc.v2x:10.45.1.0/24:10.45.1.1:ogstun2:URLLC"
    "3:mmtc.testbed:10.45.2.0/24:10.45.2.1:ogstun3:mMTC"
)

# Configuration directories
OPEN5GS_CONFIG_DIR="/etc/open5gs"
BACKUP_DIR="/etc/open5gs/backup"
UTILS_DIR="/etc/open5gs/utils"
LOG_DIR="/var/log/open5gs"

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

log_header() {
    echo -e "${PURPLE}$1${NC}"
}

log_section() {
    echo -e "${CYAN}=== $1 ===${NC}"
}

print_banner() {
    echo -e "${PURPLE}================================================================${NC}"
    echo -e "${PURPLE}  $SCRIPT_NAME v$VERSION${NC}"
    echo -e "${PURPLE}  Supporting 3 Network Slices: eMBB, URLLC, mMTC${NC}"
    echo -e "${PURPLE}  Author: $AUTHOR${NC}"
    echo -e "${PURPLE}================================================================${NC}"
}

print_usage() {
    cat << EOF
Usage: $0 [OPTION]

OPTIONS:
    --install    Install all required packages (MongoDB, Node.js, Open5GS)
    --configure  Configure all Open5GS services with 3-slice setup
    --launch     Start all Open5GS services and create network interfaces
    --all        Complete installation, configuration, and launch (recommended)
    --clean      Remove Open5GS installation and configurations
    --status     Show current installation and service status
    --help       Show this help message

NETWORK SLICES:
    eMBB    (SST:1) - embb.testbed    - 10.45.0.0/24 - ogstun
    URLLC   (SST:2) - urllc.v2x       - 10.45.1.0/24 - ogstun2  
    mMTC    (SST:3) - mmtc.testbed    - 10.45.2.0/24 - ogstun3

EXAMPLES:
    $0 --all          # Complete fresh installation
    $0 --install      # Install packages only
    $0 --configure    # Configure services only
    $0 --launch       # Start services and setup network
    $0 --status       # Check current status

EOF
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Create directories
create_directories() {
    log_info "Creating required directories..."
    
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$UTILS_DIR"
    mkdir -p "$LOG_DIR"
    
    # Set proper permissions
    chmod 755 "$OPEN5GS_CONFIG_DIR"
    chmod 755 "$BACKUP_DIR"
    chmod 755 "$UTILS_DIR"
    chmod 755 "$LOG_DIR"
    
    log_info "Directories created successfully"
}

# Backup existing configurations
backup_configurations() {
    log_info "Backing up existing configurations..."
    
    local backup_timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/backup_$backup_timestamp"
    
    mkdir -p "$backup_path"
    
    # Backup existing YAML files if they exist
    if ls "$OPEN5GS_CONFIG_DIR"/*.yaml 1> /dev/null 2>&1; then
        cp "$OPEN5GS_CONFIG_DIR"/*.yaml "$backup_path/" 2>/dev/null || true
        log_info "Existing configurations backed up to: $backup_path"
    else
        log_debug "No existing configurations to backup"
    fi
}

# Install MongoDB
install_mongodb() {
    log_section "Installing MongoDB"
    
    # Add MongoDB repository key
    log_info "Adding MongoDB repository..."
    curl -fsSL https://pgp.mongodb.com/server-8.0.asc | gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
    
    # Add MongoDB repository
    echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-8.0.list
    
    # Update package list and install MongoDB
    log_info "Updating package lists..."
    apt update
    
    log_info "Installing MongoDB..."
    apt install -y mongodb-org
    
    # Start and enable MongoDB service
    log_info "Starting MongoDB service..."
    systemctl start mongod
    systemctl enable mongod
    
    # Verify MongoDB installation
    if systemctl is-active --quiet mongod; then
        log_info "MongoDB installed and running successfully"
    else
        log_error "MongoDB installation failed or service not running"
        exit 1
    fi
}

# Install Node.js
install_nodejs() {
    log_section "Installing Node.js"
    
    # Install prerequisites
    log_info "Installing Node.js prerequisites..."
    apt update
    apt install -y ca-certificates curl gnupg
    
    # Add NodeSource repository
    log_info "Adding NodeSource repository..."
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    
    # Create repository entry
    NODE_MAJOR=20
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
    
    # Update and install Node.js
    log_info "Installing Node.js $NODE_MAJOR..."
    apt update
    apt install nodejs -y
    
    # Verify installation
    local node_version=$(node --version 2>/dev/null || echo "Not installed")
    local npm_version=$(npm --version 2>/dev/null || echo "Not installed")
    
    log_info "Node.js version: $node_version"
    log_info "npm version: $npm_version"
}

# Install Open5GS
install_open5gs() {
    log_section "Installing Open5GS"
    
    # Add Open5GS repository
    log_info "Adding Open5GS repository..."
    add-apt-repository -y ppa:open5gs/latest
    
    # Update package list
    log_info "Updating package lists..."
    apt update
    
    # Install Open5GS
    log_info "Installing Open5GS packages..."
    apt install -y open5gs
    
    # Verify installation
    if dpkg -l | grep -q open5gs; then
        log_info "Open5GS installed successfully"
    else
        log_error "Open5GS installation failed"
        exit 1
    fi
}

# Install Open5GS WebUI
install_webui() {
    log_section "Installing Open5GS WebUI"
    
    log_info "Installing Open5GS WebUI..."
    curl -fsSL https://open5gs.org/open5gs/assets/webui/install | bash -
    
    # Verify WebUI installation
    if systemctl list-unit-files | grep -q open5gs-webui; then
        log_info "Open5GS WebUI installed successfully"
        
        # Start and enable WebUI service
        systemctl start open5gs-webui
        systemctl enable open5gs-webui
        
        log_info "WebUI accessible at: http://localhost:9999"
        log_info "Default credentials: admin / 1423"
    else
        log_warn "WebUI installation may have failed, but continuing..."
    fi
}

# Main installation function
install_packages() {
    log_header "Starting package installation..."
    
    create_directories
    backup_configurations
    
    # Update system packages
    log_info "Updating system packages..."
    apt update
    apt install -y gnupg software-properties-common curl wget
    
    # Install components
    install_mongodb
    install_nodejs  
    install_open5gs
    install_webui
    
    log_info "All packages installed successfully!"
}

# Configure Open5GS services
configure_services() {
    log_header "Configuring Open5GS services..."
    
    backup_configurations
    
    # Generate all configuration files
    generate_amf_config
    generate_ausf_config
    generate_bsf_config
    generate_hss_config
    generate_mme_config
    generate_nrf_config
    generate_nssf_config
    generate_pcf_config
    generate_pcrf_config
    generate_scp_config
    generate_sgwc_config
    generate_sgwu_config
    generate_smf_config
    generate_udm_config
    generate_udr_config
    generate_upf_config
    
    # Generate utility scripts
    generate_utility_scripts
    
    log_info "All Open5GS configurations generated successfully!"
}

# Generate AMF configuration
generate_amf_config() {
    log_info "Generating AMF configuration..."
    
    cat > "$OPEN5GS_CONFIG_DIR/amf.yaml" << 'EOF'
logger:
  file:
    path: /var/log/open5gs/amf.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

amf:
  sbi:
    server:
      - address: 127.0.0.5
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
  ngap:
    server:
      - address: 127.0.0.5
  metrics:
    server:
      - address: 127.0.0.5
        port: 9090
  guami:
    - plmn_id:
        mcc: 001
        mnc: 01
      amf_id:
        region: 2
        set: 1
  tai:
    - plmn_id:
        mcc: 001
        mnc: 01
      tac: 1
  plmn_support:
    - plmn_id:
        mcc: 001
        mnc: 01
      s_nssai:
        - sst: 1
          dnn: embb.testbed
        - sst: 2
          dnn: urllc.v2x
        - sst: 3
          dnn: mmtc.testbed
  security:
    integrity_order : [ NIA2, NIA1, NIA0 ]
    ciphering_order : [ NEA0, NEA1, NEA2 ]
  network_name:
    full: Digital Hugs Network
    short: DigitalHugs <3
  amf_name: open5gs-amf0
  time:
#    t3502:
#      value: 720   # 12 minutes * 60 = 720 seconds
    t3512:
      value: 540    # 9 minutes * 60 = 540 seconds
EOF
}

# Generate AUSF configuration
generate_ausf_config() {
    log_info "Generating AUSF configuration..."
    
    cat > "$OPEN5GS_CONFIG_DIR/ausf.yaml" << 'EOF'
logger:
  file:
    path: /var/log/open5gs/ausf.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

ausf:
  sbi:
    server:
      - address: 127.0.0.11
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
EOF
}

# Generate BSF configuration
generate_bsf_config() {
    log_info "Generating BSF configuration..."
    
    cat > "$OPEN5GS_CONFIG_DIR/bsf.yaml" << 'EOF'
logger:
  file:
    path: /var/log/open5gs/bsf.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

bsf:
  sbi:
    server:
      - address: 127.0.0.15
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
EOF
}

# Generate HSS configuration
generate_hss_config() {
    log_info "Generating HSS configuration..."
    
    cat > "$OPEN5GS_CONFIG_DIR/hss.yaml" << 'EOF'
db_uri: mongodb://localhost/open5gs
logger:
  file:
    path: /var/log/open5gs/hss.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

hss:
  freeDiameter: /etc/freeDiameter/hss.conf
  metrics:
    server:
      - address: 127.0.0.8
        port: 9090
#  sms_over_ims: "sip:smsc.mnc001.mcc001.3gppnetwork.org:7060;transport=tcp"
#  use_mongodb_change_stream: true
EOF
}

# Generate MME configuration
generate_mme_config() {
    log_info "Generating MME configuration..."
    
    cat > "$OPEN5GS_CONFIG_DIR/mme.yaml" << 'EOF'
logger:
  file:
    path: /var/log/open5gs/mme.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

mme:
  freeDiameter: /etc/freeDiameter/mme.conf
  s1ap:
    server:
      - address: 127.0.0.2
  gtpc:
    server:
      - address: 127.0.0.2
    client:
      sgwc:
        - address: 127.0.0.3
      smf:
        - address: 127.0.0.4
  metrics:
    server:
      - address: 127.0.0.2
        port: 9090
  gummei:
    - plmn_id:
        mcc: 001
        mnc: 01
      mme_gid: 2
      mme_code: 1
  tai:
    - plmn_id:
        mcc: 001
        mnc: 01
      tac: 1
  security:
    integrity_order : [ EIA2, EIA1, EIA0 ]
    ciphering_order : [ EEA0, EEA1, EEA2 ]
  network_name:
    full: Digital Hugs Network
    short: DigitalHugs <3
  mme_name: open5gs-mme0
  time:
#    t3402:
#      value: 720   # 12 minutes * 60 = 720 seconds
#    t3412:
#      value: 3240  # 54 minutes * 60 = 3240 seconds
#    t3423:
#      value: 720   # 12 minutes * 60 = 720 seconds
EOF
}

# Generate NRF configuration
generate_nrf_config() {
    log_info "Generating NRF configuration..."
    
    cat > "$OPEN5GS_CONFIG_DIR/nrf.yaml" << 'EOF'
logger:
  file:
    path: /var/log/open5gs/nrf.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

nrf:
  serving:  # 5G roaming requires PLMN in NRF
    - plmn_id:
        mcc: 001
        mnc: 01
  sbi:
    server:
      - address: 127.0.0.10
        port: 7777
EOF
}

# Generate NSSF configuration
generate_nssf_config() {
    log_info "Generating NSSF configuration..."
    
    cat > "$OPEN5GS_CONFIG_DIR/nssf.yaml" << 'EOF'
logger:
  file:
    path: /var/log/open5gs/nssf.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

nssf:
  sbi:
    server:
      - address: 127.0.0.14
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
      nsi:
        - uri: http://127.0.0.10:7777
          s_nssai:
            sst: 1
EOF
}

# Generate PCF configuration
generate_pcf_config() {
    log_info "Generating PCF configuration..."
    
    cat > "$OPEN5GS_CONFIG_DIR/pcf.yaml" << 'EOF'
db_uri: mongodb://localhost/open5gs
logger:
  file:
    path: /var/log/open5gs/pcf.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

pcf:
  sbi:
    server:
      - address: 127.0.0.13
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
  metrics:
    server:
      - address: 127.0.0.13
        port: 9090
EOF
}

# Generate PCRF configuration
generate_pcrf_config() {
    log_info "Generating PCRF configuration..."
    
    cat > "$OPEN5GS_CONFIG_DIR/pcrf.yaml" << 'EOF'
db_uri: mongodb://localhost/open5gs
logger:
  file:
    path: /var/log/open5gs/pcrf.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64
pcrf:
  freeDiameter: /etc/freeDiameter/pcrf.conf
  metrics:
    server:
      - address: 127.0.0.9
        port: 9090
EOF
}

# Generate SCP configuration
generate_scp_config() {
    log_info "Generating SCP configuration..."
    
    cat > "$OPEN5GS_CONFIG_DIR/scp.yaml" << 'EOF'
logger:
  file:
    path: /var/log/open5gs/scp.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

scp:
  sbi:
    server:
      - address: 127.0.0.200
        port: 7777
    client:
      nrf:
        - uri: http://127.0.0.10:7777
EOF
}

# Generate SGWC configuration
generate_sgwc_config() {
    log_info "Generating SGWC configuration..."
    
    cat > "$OPEN5GS_CONFIG_DIR/sgwc.yaml" << 'EOF'
logger:
  file:
    path: /var/log/open5gs/sgwc.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

sgwc:
  gtpc:
    server:
      - address: 127.0.0.3
  pfcp:
    server:
      - address: 127.0.0.3
    client:
      sgwu:
        - address: 127.0.0.6
EOF
}

# Generate SGWU configuration
generate_sgwu_config() {
    log_info "Generating SGWU configuration..."
    
    cat > "$OPEN5GS_CONFIG_DIR/sgwu.yaml" << 'EOF'
logger:
  file:
    path: /var/log/open5gs/sgwu.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

sgwu:
  pfcp:
    server:
      - address: 127.0.0.6
    client:
#      sgwc:    # SGW-U PFCP Client try to associate SGW-C PFCP Server
#        - address: 127.0.0.3
  gtpu:
    server:
      - address: 127.0.0.6
EOF
}

# Generate SMF configuration
generate_smf_config() {
    log_info "Generating SMF configuration..."
    
    cat > "$OPEN5GS_CONFIG_DIR/smf.yaml" << 'EOF'
logger:
  file:
    path: /var/log/open5gs/smf.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

smf:
  sbi:
    server:
      - address: 127.0.0.4
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
  pfcp:
    server:
      - address: 127.0.0.4
    client:
      upf:
        - address: 127.0.0.7
          dnn: ['embb.testbed', 'urllc.v2x', 'mmtc.testbed']
  gtpc:
    server:
      - address: 127.0.0.4
  gtpu:
    server:
      - address: 127.0.0.4
  metrics:
    server:
      - address: 127.0.0.4
        port: 9090
  session:
    - subnet: 10.45.0.0/24
      sst: 1
      # sd: 000001
      dnn: embb.testbed
      gateway: 10.45.0.1
    - subnet: 10.45.1.0/24
      sst: 2
      # sd: 000002
      dnn: urllc.v2x
      gateway: 10.45.1.1
    - subnet: 10.45.2.0/24
      sst: 3
      # sd: 000003
      dnn: mmtc.testbed
      gateway: 10.45.2.1
  dns:
    - 8.8.8.8
    - 8.8.4.4
    - 2001:4860:4860::8888
    - 2001:4860:4860::8844
  mtu: 1400
#  p-cscf:
#    - 127.0.0.1
#    - ::1
#  ctf:
#    enabled: auto   # auto(default)|yes|no
  freeDiameter: /etc/freeDiameter/smf.conf
  info:
    - s_nssai:
        - sst: 1
          # sd: 000001
          dnn:
            - embb.testbed
        - sst: 2
          # sd: 000002
          dnn:
            - urllc.v2x
        - sst: 3
          # sd: 000003
          dnn:
            - mmtc.testbed
      tai:
        - plmn_id:
            mcc: 001
            mnc: 01
          tac: 1
EOF
}

# Generate UDM configuration
generate_udm_config() {
    log_info "Generating UDM configuration..."
    
    cat > "$OPEN5GS_CONFIG_DIR/udm.yaml" << 'EOF'
logger:
  file:
    path: /var/log/open5gs/udm.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

udm:
  hnet:
    - id: 1
      scheme: 1
      key: /etc/open5gs/hnet/curve25519-1.key
    - id: 2
      scheme: 2
      key: /etc/open5gs/hnet/secp256r1-2.key
    - id: 3
      scheme: 1
      key: /etc/open5gs/hnet/curve25519-3.key
    - id: 4
      scheme: 2
      key: /etc/open5gs/hnet/secp256r1-4.key
    - id: 5
      scheme: 1
      key: /etc/open5gs/hnet/curve25519-5.key
    - id: 6
      scheme: 2
      key: /etc/open5gs/hnet/secp256r1-6.key
  sbi:
    server:
      - address: 127.0.0.12
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
EOF
}

# Generate UDR configuration
generate_udr_config() {
    log_info "Generating UDR configuration..."
    
    cat > "$OPEN5GS_CONFIG_DIR/udr.yaml" << 'EOF'
db_uri: mongodb://localhost/open5gs
logger:
  file:
    path: /var/log/open5gs/udr.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

udr:
  sbi:
    server:
      - address: 127.0.0.20
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
EOF
}

# Generate UPF configuration
generate_upf_config() {
    log_info "Generating UPF configuration..."
    
    cat > "$OPEN5GS_CONFIG_DIR/upf.yaml" << 'EOF'
logger:
  file:
    path: /var/log/open5gs/upf.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

upf:
  pfcp:
    server:
      - address: 127.0.0.7
    client:
     smf:     #  UPF PFCP Client try to associate SMF PFCP Server
       - address: 127.0.0.4
  gtpu:
    server:
      - address: 127.0.0.7
  session:
    - subnet: 10.45.0.0/24
      sst: 1
      # sd: 000001
      dnn: embb.testbed
      gateway: 10.45.0.1
      dev: ogstun
    - subnet: 10.45.1.0/24
      sst: 2
      # sd: 000002
      dnn: urllc.v2x
      gateway: 10.45.1.1
      dev: ogstun2
    - subnet: 10.45.2.0/24
      sst: 3
      # sd: 000003
      dnn: mmtc.testbed
      gateway: 10.45.2.1
      dev: ogstun3
    # - subnet: 2001:db8:cafe::/48
    #   gateway: 2001:db8:cafe::1
  metrics:
    server:
      - address: 127.0.0.7
        port: 9090
EOF
}

# Generate utility scripts
generate_utility_scripts() {
    log_info "Generating utility scripts..."
    
    # Create TUN interface script
    create_tun_interface_script
    
    # Create iptables management script
    create_iptables_script
    
    # Create service restart script
    create_service_restart_script
    
    # Make scripts executable
    chmod +x "$UTILS_DIR"/*.sh
    
    log_info "Utility scripts created and made executable"
}

# Create TUN interface management script
create_tun_interface_script() {
    cat > "$UTILS_DIR/create-tun-interfaces.sh" << 'EOF'
#!/bin/bash

# Open5GS TUN Interface Management Script
# Usage: sudo ./create-tun-interfaces.sh [--add|--remove]

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_usage() {
    echo "Usage: $0 [--add|--remove]"
    echo ""
    echo "TUN Interfaces:"
    echo "  ogstun   (10.45.0.1/24)  - eMBB slice"
    echo "  ogstun2  (10.45.1.1/24)  - URLLC slice"
    echo "  ogstun3  (10.45.2.1/24)  - mMTC slice"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

enable_ipv4_forwarding() {
    print_status "Enabling IPv4 forwarding..."
    echo 1 > /proc/sys/net/ipv4/ip_forward
    if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf 2>/dev/null; then
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
        print_success "IPv4 forwarding enabled and made persistent"
    else
        print_success "IPv4 forwarding enabled"
    fi
}

interface_exists() {
    ip link show "$1" &> /dev/null
}

add_tun_interface() {
    local interface=$1
    local ip_addr=$2
    local subnet=$3
    local description=$4
    
    print_status "Setting up $interface ($description)..."
    
    if interface_exists "$interface"; then
        print_warning "Interface $interface already exists, updating..."
        ip addr flush dev "$interface" 2>/dev/null
        ip addr add "$ip_addr" dev "$interface"
        ip link set "$interface" up
    else
        ip tuntap add name "$interface" mode tun
        ip addr add "$ip_addr" dev "$interface"
        ip link set "$interface" up
        print_success "TUN interface $interface created and configured"
    fi
    
    # Add NAT rule
    iptables -t nat -D POSTROUTING -s "$subnet" ! -o "$interface" -j MASQUERADE 2>/dev/null || true
    iptables -t nat -A POSTROUTING -s "$subnet" ! -o "$interface" -j MASQUERADE
    print_success "NAT rule added for $subnet via $interface"
}

remove_tun_interface() {
    local interface=$1
    local subnet=$2
    local description=$3
    
    print_status "Removing $interface ($description)..."
    
    # Remove NAT rule
    iptables -t nat -D POSTROUTING -s "$subnet" ! -o "$interface" -j MASQUERADE 2>/dev/null || true
    
    if interface_exists "$interface"; then
        ip link set "$interface" down 2>/dev/null
        ip tuntap del name "$interface" mode tun
        print_success "TUN interface $interface removed"
    else
        print_warning "Interface $interface does not exist"
    fi
}

add_all_interfaces() {
    print_status "Creating Open5GS TUN interfaces..."
    enable_ipv4_forwarding
    
    add_tun_interface "ogstun"  "10.45.0.1/24" "10.45.0.0/24" "eMBB slice"
    add_tun_interface "ogstun2" "10.45.1.1/24" "10.45.1.0/24" "URLLC slice"
    add_tun_interface "ogstun3" "10.45.2.1/24" "10.45.2.0/24" "mMTC slice"
    
    print_success "All TUN interfaces configured!"
}

remove_all_interfaces() {
    print_status "Removing Open5GS TUN interfaces..."
    
    remove_tun_interface "ogstun"  "10.45.0.0/24" "eMBB slice"
    remove_tun_interface "ogstun2" "10.45.1.0/24" "URLLC slice"
    remove_tun_interface "ogstun3" "10.45.2.0/24" "mMTC slice"
    
    print_success "All TUN interfaces removed!"
}

main() {
    case "$1" in
        --add)
            check_root
            add_all_interfaces
            ;;
        --remove)
            check_root
            remove_all_interfaces
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
EOF
}

# Create iptables management script
create_iptables_script() {
    cat > "$UTILS_DIR/setup-iptables.sh" << 'EOF'
#!/bin/bash

# Open5GS Iptables Management Script
# Usage: sudo ./setup-iptables.sh [--add|--remove|--status]

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

TUN_INTERFACES=("ogstun" "ogstun2" "ogstun3")
SUBNETS=("10.45.0.0/24" "10.45.1.0/24" "10.45.2.0/24")

get_internet_interface() {
    ip route | grep default | awk '{print $5}' | head -1
}

add_rules() {
    print_status "Adding iptables rules for Open5GS..."
    
    # Enable IP forwarding
    sysctl -w net.ipv4.ip_forward=1
    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    fi
    
    local inet_iface=$(get_internet_interface)
    print_status "Using internet interface: $inet_iface"
    
    # Add INPUT rules
    for interface in "${TUN_INTERFACES[@]}"; do
        iptables -I INPUT -i "$interface" -j ACCEPT 2>/dev/null || true
    done
    
    # Add FORWARD rules
    for interface in "${TUN_INTERFACES[@]}"; do
        iptables -I FORWARD -i "$interface" -j ACCEPT 2>/dev/null || true
        iptables -I FORWARD -o "$interface" -j ACCEPT 2>/dev/null || true
    done
    
    # Add NAT rules
    for subnet in "${SUBNETS[@]}"; do
        iptables -t nat -A POSTROUTING -s "$subnet" -o "$inet_iface" -j MASQUERADE 2>/dev/null || true
    done
    
    print_success "Iptables rules added successfully!"
}

remove_rules() {
    print_status "Removing iptables rules for Open5GS..."
    
    local inet_iface=$(get_internet_interface)
    
    # Remove INPUT rules
    for interface in "${TUN_INTERFACES[@]}"; do
        while iptables -C INPUT -i "$interface" -j ACCEPT 2>/dev/null; do
            iptables -D INPUT -i "$interface" -j ACCEPT
        done
    done
    
    # Remove FORWARD rules
    for interface in "${TUN_INTERFACES[@]}"; do
        while iptables -C FORWARD -i "$interface" -j ACCEPT 2>/dev/null; do
            iptables -D FORWARD -i "$interface" -j ACCEPT
        done
        while iptables -C FORWARD -o "$interface" -j ACCEPT 2>/dev/null; do
            iptables -D FORWARD -o "$interface" -j ACCEPT
        done
    done
    
    # Remove NAT rules
    for subnet in "${SUBNETS[@]}"; do
        while iptables -t nat -C POSTROUTING -s "$subnet" -o "$inet_iface" -j MASQUERADE 2>/dev/null; do
            iptables -t nat -D POSTROUTING -s "$subnet" -o "$inet_iface" -j MASQUERADE
        done
    done
    
    print_success "Iptables rules removed successfully!"
}

show_status() {
    print_status "Current iptables status for Open5GS:"
    echo "=== INPUT CHAIN ==="
    iptables -L INPUT -n -v --line-numbers | grep -E "(ogstun|Chain|target)" || echo "No rules found"
    echo "=== FORWARD CHAIN ==="
    iptables -L FORWARD -n -v --line-numbers | grep -E "(ogstun|Chain|target)" || echo "No rules found"
    echo "=== NAT POSTROUTING ==="
    iptables -t nat -L POSTROUTING -n -v --line-numbers | grep -E "(10\.45\.|Chain|target)" || echo "No rules found"
}

case "$1" in
    --add)
        add_rules
        ;;
    --remove)
        remove_rules
        ;;
    --status)
        show_status
        ;;
    *)
        echo "Usage: $0 [--add|--remove|--status]"
        exit 1
        ;;
esac
EOF
}

# Create service restart script
create_service_restart_script() {
    cat > "$UTILS_DIR/restart-services.sh" << 'EOF'
#!/bin/bash

# Open5GS Services Restart Script
# Usage: sudo ./restart-services.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

SERVICES=(
    "open5gs-nrfd"
    "open5gs-scpd"
    "open5gs-ausfd"
    "open5gs-udrd"
    "open5gs-udmd"
    "open5gs-pcfd"
    "open5gs-bsfd"
    "open5gs-nssfd"
    "open5gs-amfd"
    "open5gs-upfd"
    "open5gs-smfd"
    "open5gs-sgwcd"
    "open5gs-sgwud"
    "open5gs-mmed"
    "open5gs-hssd"
    "open5gs-pcrfd"
)

print_status "Restarting Open5GS services..."
systemctl daemon-reload

success_count=0
failed_count=0

for service in "${SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "^${service}.service"; then
        print_status "Restarting ${service}.service..."
        systemctl stop "${service}.service" 2>/dev/null || true
        sleep 1
        if systemctl restart "${service}.service"; then
            if systemctl is-active --quiet "${service}.service"; then
                print_success "${service}.service restarted successfully"
                ((success_count++))
            else
                print_error "${service}.service failed to start"
                ((failed_count++))
            fi
        else
            print_error "Failed to restart ${service}.service"
            ((failed_count++))
        fi
    fi
done

print_status "Summary: $success_count successful, $failed_count failed"

if [ $failed_count -gt 0 ]; then
    exit 1
else
    print_success "All services restarted successfully!"
fi
EOF
}

# Launch Open5GS services
launch_services() {
    log_header "Launching Open5GS services..."
    
    # Reload systemd daemon
    log_info "Reloading systemd daemon..."
    systemctl daemon-reload
    
    # Create TUN interfaces
    log_info "Creating TUN interfaces..."
    if [[ -f "$UTILS_DIR/create-tun-interfaces.sh" ]]; then
        bash "$UTILS_DIR/create-tun-interfaces.sh" --add
    else
        log_error "TUN interface script not found"
        exit 1
    fi
    
    # Setup iptables rules
    log_info "Setting up iptables rules..."
    if [[ -f "$UTILS_DIR/setup-iptables.sh" ]]; then
        bash "$UTILS_DIR/setup-iptables.sh" --add
    else
        log_error "Iptables script not found"
        exit 1
    fi
    
    # Start services
    log_info "Starting Open5GS services..."
    if [[ -f "$UTILS_DIR/restart-services.sh" ]]; then
        bash "$UTILS_DIR/restart-services.sh"
    else
        log_error "Service restart script not found"
        exit 1
    fi
    
    # Start WebUI if available
    if systemctl list-unit-files | grep -q open5gs-webui; then
        log_info "Starting Open5GS WebUI..."
        systemctl start open5gs-webui
        systemctl enable open5gs-webui
    fi
    
    log_info "Open5GS launched successfully!"
    show_final_status
}

# Clean installation
clean_installation() {
    log_header "Cleaning Open5GS installation..."
    
    log_warn "This will remove Open5GS installation and configurations!"
    read -p "Are you sure you want to continue? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Clean operation cancelled"
        return 0
    fi
    
    # Stop services
    log_info "Stopping Open5GS services..."
    systemctl stop open5gs-* 2>/dev/null || true
    
    # Remove TUN interfaces
    log_info "Removing TUN interfaces..."
    if [[ -f "$UTILS_DIR/create-tun-interfaces.sh" ]]; then
        bash "$UTILS_DIR/create-tun-interfaces.sh" --remove
    fi
    
    # Remove iptables rules
    log_info "Removing iptables rules..."
    if [[ -f "$UTILS_DIR/setup-iptables.sh" ]]; then
        bash "$UTILS_DIR/setup-iptables.sh" --remove
    fi
    
    # Remove packages
    log_info "Removing Open5GS packages..."
    apt remove --purge -y open5gs-* 2>/dev/null || true
    
    # Remove configurations (keep backups)
    log_info "Cleaning configurations (backups preserved)..."
    rm -f "$OPEN5GS_CONFIG_DIR"/*.yaml 2>/dev/null || true
    
    log_info "Open5GS cleaned successfully!"
}

# Show installation status
show_status() {
    print_banner
    log_section "Installation Status"
    
    # Check packages
    log_info "Package Status:"
    if dpkg -l | grep -q mongodb-org; then
        echo "  ✓ MongoDB: Installed"
    else
        echo "  ✗ MongoDB: Not installed"
    fi
    
    if command -v node &> /dev/null; then
        echo "  ✓ Node.js: $(node --version)"
    else
        echo "  ✗ Node.js: Not installed"
    fi
    
    if dpkg -l | grep -q open5gs; then
        echo "  ✓ Open5GS: Installed"
    else
        echo "  ✗ Open5GS: Not installed"
    fi
    
    # Check services
    log_info "Service Status:"
    local services=("mongod" "open5gs-nrfd" "open5gs-amfd" "open5gs-smfd" "open5gs-upfd")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo "  ✓ $service: Running"
        else
            echo "  ✗ $service: Not running"
        fi
    done
    
    # Check interfaces
    log_info "Network Interfaces:"
    for interface in ogstun ogstun2 ogstun3; do
        if ip link show "$interface" &> /dev/null; then
            local ip_addr=$(ip addr show "$interface" | grep -oP 'inet \K[^/]+' || echo "No IP")
            echo "  ✓ $interface: UP (IP: $ip_addr)"
        else
            echo "  ✗ $interface: Down/Not exists"
        fi
    done
    
    # Check configuration files
    log_info "Configuration Files:"
    if [[ -f "$OPEN5GS_CONFIG_DIR/amf.yaml" ]]; then
        echo "  ✓ Configuration files: Present"
    else
        echo "  ✗ Configuration files: Missing"
    fi
    
    # Show WebUI info
    if systemctl list-unit-files | grep -q open5gs-webui; then
        if systemctl is-active --quiet open5gs-webui; then
            echo ""
            log_info "WebUI Access:"
            echo "  URL: http://localhost:9999"
            echo "  Username: admin"
            echo "  Password: 1423"
        fi
    fi
}

# Show final status after successful installation
show_final_status() {
    echo ""
    log_header "Open5GS Installation Complete!"
    echo ""
    log_info "Network Slices Configuration:"
    echo "  eMBB  (SST:1) - embb.testbed  - 10.45.0.0/24 - ogstun"
    echo "  URLLC (SST:2) - urllc.v2x    - 10.45.1.0/24 - ogstun2"
    echo "  mMTC  (SST:3) - mmtc.testbed - 10.45.2.0/24 - ogstun3"
    echo ""
    log_info "Management Tools:"
    echo "  WebUI: http://localhost:9999 (admin/1423)"
    echo "  Config: $OPEN5GS_CONFIG_DIR/"
    echo "  Utils:  $UTILS_DIR/"
    echo "  Logs:   $LOG_DIR/"
    echo ""
    log_info "Utility Scripts:"
    echo "  TUN Interfaces: $UTILS_DIR/create-tun-interfaces.sh"
    echo "  Iptables:       $UTILS_DIR/setup-iptables.sh"
    echo "  Services:       $UTILS_DIR/restart-services.sh"
    echo ""
    log_info "Next Steps:"
    echo "  1. Access WebUI to add subscriber information"
    echo "  2. Configure UERANSIM to connect to this core network"
    echo "  3. Test with UE simulator"
    echo ""
    log_success "Open5GS is ready for UERANSIM integration!"
}

# Main function
main() {
    case "${1:-}" in
        --install)
            check_root
            install_packages
            ;;
        --configure)
            check_root
            configure_services
            ;;
        --launch)
            check_root
            launch_services
            ;;
        --all)
            check_root
            print_banner
            install_packages
            configure_services
            launch_services
            ;;
        --clean)
            check_root
            clean_installation
            ;;
        --status)
            show_status
            ;;
        --help|-h|help)
            print_usage
            ;;
        *)
            log_error "Invalid or missing option"
            print_usage
            exit 1
            ;;
    esac
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi