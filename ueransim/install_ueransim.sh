#!/bin/bash

################################################################################
# UERANSIM Complete Installation Script
# Author: Automated Setup Script
# Description: Installs UERANSIM from scratch including gNB/UE configuration
#              and testing scripts creation
################################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration variables
INSTALL_DIR="$HOME"
UERANSIM_DIR="$HOME/UERANSIM"
USERNAME=$(whoami)

# Logging
LOG_FILE="/tmp/ueransim_install_$(date +%Y%m%d_%H%M%S).log"

################################################################################
# Helper Functions
################################################################################

log() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

section() {
    echo -e "\n${BLUE}=== $1 ===${NC}" | tee -a "$LOG_FILE"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        error "$1 is not installed or not in PATH"
    fi
}

################################################################################
# Pre-installation Checks
################################################################################

pre_check() {
    section "Pre-installation Checks"
    
    # Check if running as root (should not)
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root"
    fi
    
    # Check OS
    if [[ ! -f /etc/os-release ]]; then
        error "Cannot determine OS version"
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]] && [[ "$ID" != "debian" ]]; then
        warn "This script is designed for Ubuntu/Debian. Other distributions may not work properly."
    fi
    
    log "OS: $PRETTY_NAME"
    log "User: $USERNAME"
    log "Install directory: $INSTALL_DIR"
    log "Log file: $LOG_FILE"
}

################################################################################
# System Update and Dependencies Installation
################################################################################

install_dependencies() {
    section "Installing System Dependencies"
    
    log "Updating package lists..."
    sudo apt update >> "$LOG_FILE" 2>&1
    
    log "Upgrading system packages..."
    sudo apt upgrade -y >> "$LOG_FILE" 2>&1
    
    log "Installing build dependencies..."
    sudo apt install -y \
        make \
        gcc \
        g++ \
        libsctp-dev \
        lksctp-tools \
        iproute2 \
        git \
        nano \
        wget \
        curl \
        iperf3 >> "$LOG_FILE" 2>&1
    
    log "Installing CMake via snap..."
    if ! command -v cmake &> /dev/null; then
        sudo snap install cmake --classic >> "$LOG_FILE" 2>&1
    else
        log "CMake already installed"
    fi
    
    # Verify installations
    check_command "make"
    check_command "gcc"
    check_command "g++"
    check_command "cmake"
    check_command "git"
    check_command "iperf3"
    
    log "All dependencies installed successfully"
}

################################################################################
# UERANSIM Repository Clone and Build
################################################################################

clone_and_build() {
    section "Cloning and Building UERANSIM"
    
    # Remove existing directory if present
    if [[ -d "$UERANSIM_DIR" ]]; then
        warn "UERANSIM directory already exists. Removing..."
        rm -rf "$UERANSIM_DIR"
    fi
    
    log "Cloning UERANSIM repository..."
    cd "$INSTALL_DIR"
    git clone https://github.com/aligungr/UERANSIM >> "$LOG_FILE" 2>&1
    
    log "Building UERANSIM..."
    cd "$UERANSIM_DIR"
    make -j$(nproc) >> "$LOG_FILE" 2>&1
    
    # Verify build
    if [[ ! -f "$UERANSIM_DIR/build/nr-gnb" ]] || [[ ! -f "$UERANSIM_DIR/build/nr-ue" ]]; then
        error "Build failed - binaries not found"
    fi
    
    log "UERANSIM built successfully"
    log "Binaries available in: $UERANSIM_DIR/build/"
}

################################################################################
# Configuration Files Creation
################################################################################

create_gnb_config() {
    section "Creating gNB Configuration"
    
    local config_file="$UERANSIM_DIR/config/open5gs-gnb.yaml"
    
    log "Creating gNB configuration file: $config_file"
    
    cat > "$config_file" << 'EOF'
mcc: '001'          # Mobile Country Code value
mnc: '01'           # Mobile Network Code value (2 or 3 digits)

nci: '0x000000010'  # NR Cell Identity (36-bit)
idLength: 32        # NR gNB ID length in bits [22...32]
tac: 1              # Tracking Area Code

linkIp: 127.0.0.1   # gNB's local IP address for Radio Link Simulation (Usually same with local IP)
ngapIp: 127.0.0.1   # gNB's local IP address for N2 Interface (Usually same with local IP)
gtpIp: 127.0.0.1    # gNB's local IP address for N3 Interface (Usually same with local IP)

# List of AMF address information
amfConfigs:
  - address: 127.0.0.5
    port: 38412

# List of supported S-NSSAIs by this gNB
slices:
  - sst: 1
    sd: 000001
    dnn: 'embb.testbed'
  - sst: 2
    sd: 000002
    dnn: 'urllc.v2x'
  - sst: 3
    sd: 000003
    dnn: 'mmtc.testbed'

# Indicates whether or not SCTP stream number errors should be ignored.
ignoreStreamIds: true
EOF
    
    log "gNB configuration created successfully"
}

create_ue_configs() {
    section "Creating UE Configurations"
    
    # eMBB UE Configuration
    log "Creating eMBB UE configuration..."
    cat > "$UERANSIM_DIR/config/open5gs-ue-embb.yaml" << 'EOF'
# IMSI number of the UE. IMSI = [MCC|MNC|MSISDN] (In total 15 digits)
supi: 'imsi-001011000000001'
# Mobile Country Code value of HPLMN
mcc: '001'
# Mobile Network Code value of HPLMN (2 or 3 digits)
mnc: '01'
# SUCI Protection Scheme : 0 for Null-scheme, 1 for Profile A and 2 for Profile B
protectionScheme: 0
# Home Network Public Key for protecting with SUCI Profile A
homeNetworkPublicKey: '5a8d38864820197c3394b92613b20b91633cbd897119273bf8e4a6f4eec0a650'
# Home Network Public Key ID for protecting with SUCI Profile A
homeNetworkPublicKeyId: 1
# Routing Indicator
routingIndicator: '0000'

# Permanent subscription key
key: '465B5CE8B199B49FAA5F0A2EE238A6BC'
# Operator code (OP or OPC) of the UE
op: 'E8ED289DEBA952E4283B54E88E6183CA'
# This value specifies the OP type and it can be either 'OP' or 'OPC'
opType: 'OPC'
# Authentication Management Field (AMF) value
amf: '8000'
# IMEI number of the device. It is used if no SUPI is provided
imei: '356938035643803'
# IMEISV number of the device. It is used if no SUPI and IMEI is provided
imeiSv: '4370816125816151'

# Network mask used for the UE's TUN interface to define the subnet size  
tunNetmask: '255.255.255.0'

# List of gNB IP addresses for Radio Link Simulation
gnbSearchList:
  - 127.0.0.1

# UAC Access Identities Configuration
uacAic:
  mps: false
  mcs: false

# UAC Access Control Class
uacAcc:
  normalClass: 0
  class11: false
  class12: false
  class13: false
  class14: false
  class15: false

# Initial PDU sessions to be established
sessions:
  - type: 'IPv4'
    apn: 'embb.testbed'
    slice:
      sst: 1
      sd: 000001

# Configured NSSAI for this UE by HPLMN
configured-nssai:
  - sst: 1
    sd: 000001

# Default Configured NSSAI for this UE
default-nssai:
  - sst: 1
    sd: 000001

# Supported integrity algorithms by this UE
integrity:
  IA1: true
  IA2: true
  IA3: true

# Supported encryption algorithms by this UE
ciphering:
  EA1: true
  EA2: true
  EA3: true

# Integrity protection maximum data rate for user plane
integrityMaxRate:
  uplink: 'full'
  downlink: 'full'
EOF

    # URLLC UE Configuration
    log "Creating URLLC UE configuration..."
    cat > "$UERANSIM_DIR/config/open5gs-ue-urllc.yaml" << 'EOF'
# IMSI number of the UE. IMSI = [MCC|MNC|MSISDN] (In total 15 digits)
supi: 'imsi-001012000000001'
# Mobile Country Code value of HPLMN
mcc: '001'
# Mobile Network Code value of HPLMN (2 or 3 digits)
mnc: '01'
# SUCI Protection Scheme : 0 for Null-scheme, 1 for Profile A and 2 for Profile B
protectionScheme: 0
# Home Network Public Key for protecting with SUCI Profile A
homeNetworkPublicKey: '5a8d38864820197c3394b92613b20b91633cbd897119273bf8e4a6f4eec0a650'
# Home Network Public Key ID for protecting with SUCI Profile A
homeNetworkPublicKeyId: 1
# Routing Indicator
routingIndicator: '0000'

# Permanent subscription key
key: '465B5CE8B199B49FAA5F0A2EE238A6BC'
# Operator code (OP or OPC) of the UE
op: 'E8ED289DEBA952E4283B54E88E6183CA'
# This value specifies the OP type and it can be either 'OP' or 'OPC'
opType: 'OPC'
# Authentication Management Field (AMF) value
amf: '8000'
# IMEI number of the device. It is used if no SUPI is provided
imei: '356938035643803'
# IMEISV number of the device. It is used if no SUPI and IMEI is provided
imeiSv: '4370816125816151'

# Network mask used for the UE's TUN interface to define the subnet size  
tunNetmask: '255.255.255.0'

# List of gNB IP addresses for Radio Link Simulation
gnbSearchList:
  - 127.0.0.1

# UAC Access Identities Configuration
uacAic:
  mps: false
  mcs: false

# UAC Access Control Class
uacAcc:
  normalClass: 0
  class11: false
  class12: false
  class13: false
  class14: false
  class15: false

# Initial PDU sessions to be established
sessions:
  - type: 'IPv4'
    apn: 'urllc.v2x'
    slice:
      sst: 2
      sd: 000002

# Configured NSSAI for this UE by HPLMN
configured-nssai:
  - sst: 2
    sd: 000002

# Default Configured NSSAI for this UE
default-nssai:
  - sst: 2
    sd: 000002

# Supported integrity algorithms by this UE
integrity:
  IA1: true
  IA2: true
  IA3: true

# Supported encryption algorithms by this UE
ciphering:
  EA1: true
  EA2: true
  EA3: true

# Integrity protection maximum data rate for user plane
integrityMaxRate:
  uplink: 'full'
  downlink: 'full'
EOF

    # mMTC UE Configuration
    log "Creating mMTC UE configuration..."
    cat > "$UERANSIM_DIR/config/open5gs-ue-mmtc.yaml" << 'EOF'
# IMSI number of the UE. IMSI = [MCC|MNC|MSISDN] (In total 15 digits)
supi: 'imsi-001013000000001'
# Mobile Country Code value of HPLMN
mcc: '001'
# Mobile Network Code value of HPLMN (2 or 3 digits)
mnc: '01'
# SUCI Protection Scheme : 0 for Null-scheme, 1 for Profile A and 2 for Profile B
protectionScheme: 0
# Home Network Public Key for protecting with SUCI Profile A
homeNetworkPublicKey: '5a8d38864820197c3394b92613b20b91633cbd897119273bf8e4a6f4eec0a650'
# Home Network Public Key ID for protecting with SUCI Profile A
homeNetworkPublicKeyId: 1
# Routing Indicator
routingIndicator: '0000'

# Permanent subscription key
key: '465B5CE8B199B49FAA5F0A2EE238A6BC'
# Operator code (OP or OPC) of the UE
op: 'E8ED289DEBA952E4283B54E88E6183CA'
# This value specifies the OP type and it can be either 'OP' or 'OPC'
opType: 'OPC'
# Authentication Management Field (AMF) value
amf: '8000'
# IMEI number of the device. It is used if no SUPI is provided
imei: '356938035643803'
# IMEISV number of the device. It is used if no SUPI and IMEI is provided
imeiSv: '4370816125816151'

# Network mask used for the UE's TUN interface to define the subnet size  
tunNetmask: '255.255.255.0'

# List of gNB IP addresses for Radio Link Simulation
gnbSearchList:
  - 127.0.0.1

# UAC Access Identities Configuration
uacAic:
  mps: false
  mcs: false

# UAC Access Control Class
uacAcc:
  normalClass: 0
  class11: false
  class12: false
  class13: false
  class14: false
  class15: false

# Initial PDU sessions to be established
sessions:
  - type: 'IPv4'
    apn: 'mmtc.testbed'
    slice:
      sst: 3
      sd: 000003

# Configured NSSAI for this UE by HPLMN
configured-nssai:
  - sst: 3
    sd: 000003

# Default Configured NSSAI for this UE
default-nssai:
  - sst: 3
    sd: 000003

# Supported integrity algorithms by this UE
integrity:
  IA1: true
  IA2: true
  IA3: true

# Supported encryption algorithms by this UE
ciphering:
  EA1: true
  EA2: true
  EA3: true

# Integrity protection maximum data rate for user plane
integrityMaxRate:
  uplink: 'full'
  downlink: 'full'
EOF

    log "All UE configurations created successfully"
}

################################################################################
# Testing Scripts Creation
################################################################################

create_testing_scripts() {
    section "Creating Testing Scripts"
    
    # Create testing directory
    local testing_dir="$UERANSIM_DIR/testing"
    mkdir -p "$testing_dir"
    mkdir -p "$testing_dir/testing_logs"
    
    log "Creating iperf3 testing script..."
    
    # Create the iperf3 test script
    cat > "$testing_dir/iperf3_test.sh" << 'EOF'
#!/bin/bash

# UERANSIM iperf3 Testing Script
# Tests uesimtun0, uesimtun1, and uesimtun3 interfaces
# Supports TCP/UDP, uplink/downlink, parallel streams, and duration

# Default values
SERVER=""
PARALLEL=1
DURATION=10
BUFFER_SIZE="128K"
DELAY_BETWEEN_TESTS=5
TCP_ONLY=false
UDP_ONLY=false

# Usage function
usage() {
    echo "Usage: $0 -s SERVER [-p PARALLEL] [-t DURATION] [-d DELAY] [--tcp-only] [--udp-only]"
    echo ""
    echo "Required:"
    echo "  -s SERVER     iperf3 server address (IP preferred over hostname)"
    echo ""
    echo "Optional:"
    echo "  -p PARALLEL   Number of parallel streams (default: 1)"
    echo "  -t DURATION   Test duration in seconds (default: 10)"
    echo "  -d DELAY      Delay between tests in seconds (default: 5)"
    echo "  --tcp-only    Run only TCP tests (uplink and downlink)"
    echo "  --udp-only    Run only UDP tests (uplink and downlink)"
    echo "  -h            Show this help message"
    echo ""
    echo "This script will run tests for each interface (uesimtun0, uesimtun1, uesimtun3)"
    echo "By default, runs 4 tests per interface (TCP/UDP × uplink/downlink)"
    echo "With --tcp-only: runs 2 tests per interface (TCP uplink/downlink)"
    echo "With --udp-only: runs 2 tests per interface (UDP uplink/downlink)"
    echo ""
    echo "Note: iperf3 server can only handle one client at a time."
    echo "      Use sufficient delay between tests to avoid connection errors."
    echo "      --tcp-only and --udp-only flags are mutually exclusive."
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s)
            SERVER="$2"
            shift 2
            ;;
        -p)
            PARALLEL="$2"
            shift 2
            ;;
        -t)
            DURATION="$2"
            shift 2
            ;;
        -d)
            DELAY_BETWEEN_TESTS="$2"
            shift 2
            ;;
        --tcp-only)
            TCP_ONLY=true
            shift
            ;;
        --udp-only)
            UDP_ONLY=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Check required parameters
if [ -z "$SERVER" ]; then
    echo "Error: Server address is required"
    usage
fi

# Check for conflicting flags
if [ "$TCP_ONLY" = true ] && [ "$UDP_ONLY" = true ]; then
    echo "Error: --tcp-only and --udp-only flags are mutually exclusive"
    usage
fi

# Timestamp for log files
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_DIR="$HOME/UERANSIM/testing/testing_logs"

# Test interfaces
INTERFACES=("uesimtun0" "uesimtun1" "uesimtun3")

# Determine test modes based on flags
if [ "$TCP_ONLY" = true ]; then
    TEST_MODES="TCP"
    TEST_MODE_DESC="TCP only"
elif [ "$UDP_ONLY" = true ]; then
    TEST_MODES="UDP"
    TEST_MODE_DESC="UDP only"
else
    TEST_MODES="TCP UDP"
    TEST_MODE_DESC="TCP and UDP"
fi

echo "========================================="
echo "Starting iperf3 Tests"
echo "========================================="
echo "Server: $SERVER"
echo "Parallel Streams: $PARALLEL"
echo "Duration: $DURATION seconds"
echo "Delay between tests: $DELAY_BETWEEN_TESTS seconds"
echo "Test Mode: $TEST_MODE_DESC"
echo "Timestamp: $TIMESTAMP"
echo "=========================================="
echo ""

# Check if server is reachable
echo "Checking server connectivity..."
ping -c 1 -W 2 $SERVER > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Warning: Cannot ping server $SERVER. Tests may fail."
    echo "Consider using IP address instead of hostname."
fi

# Function to run a single test
run_test() {
    local interface=$1
    local test_type=$2
    local direction=$3
    local log_file="${LOG_DIR}/${interface}_${test_type}_${direction}_${TIMESTAMP}.log"
    
    echo "Testing ${interface} - ${test_type} ${direction}..."
    
    # Build command
    cmd="../build/nr-binder ${interface} iperf3 -c ${SERVER} -P ${PARALLEL} -t ${DURATION} -w ${BUFFER_SIZE}"
    
    # Add UDP flag if needed
    if [ "$test_type" = "UDP" ]; then
        cmd="${cmd} -u -b 100M"
    fi
    
    # Add reverse flag for downlink
    if [ "$direction" = "downlink" ]; then
        cmd="${cmd} -R"
    fi
    
    # Execute and save to log
    echo "Command: ${cmd}" > "$log_file"
    echo "----------------------------------------" >> "$log_file"
    ${cmd} >> "$log_file" 2>&1
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "  ✓ Test completed successfully (log: ${log_file})"
    else
        echo "  ✗ Test failed with exit code $exit_code (check log: ${log_file})"
        # Check if it's a connection error
        if grep -q "Connection refused\|server busy" "$log_file"; then
            echo "    → iperf3 server may be busy. Consider increasing delay between tests."
        fi
    fi
    
    # Wait between tests to ensure server is ready for next connection
    echo "  Waiting ${DELAY_BETWEEN_TESTS} seconds before next test..."
    sleep $DELAY_BETWEEN_TESTS
}

# Main test loop
for interface in "${INTERFACES[@]}"; do
    echo ""
    echo "========================================="
    echo "Testing Interface: ${interface}"
    echo "========================================="
    
    # Run tests based on selected mode
    for test_type in $TEST_MODES; do
        # Test uplink
        run_test "$interface" "$test_type" "uplink"
        
        # Test downlink
        run_test "$interface" "$test_type" "downlink"
    done
    
    echo ""
done

# Summary
echo "========================================="
echo "All Tests Completed"
echo "========================================="
echo "Logs are saved in: ${LOG_DIR}"
echo "Log files pattern: {interface}_{protocol}_{direction}_${TIMESTAMP}.log"
echo ""

# Generate summary report
SUMMARY_FILE="${LOG_DIR}/summary_${TIMESTAMP}.txt"
echo "Test Summary Report" > "$SUMMARY_FILE"
echo "==================" >> "$SUMMARY_FILE"
echo "Date: $(date)" >> "$SUMMARY_FILE"
echo "Server: $SERVER" >> "$SUMMARY_FILE"
echo "Parallel Streams: $PARALLEL" >> "$SUMMARY_FILE"
echo "Duration: $DURATION seconds" >> "$SUMMARY_FILE"
echo "Test Mode: $TEST_MODE_DESC" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "Test Results:" >> "$SUMMARY_FILE"
echo "-------------" >> "$SUMMARY_FILE"

for interface in "${INTERFACES[@]}"; do
    echo "" >> "$SUMMARY_FILE"
    echo "${interface}:" >> "$SUMMARY_FILE"
    for test_type in $TEST_MODES; do
        for direction in uplink downlink; do
            log_file="${LOG_DIR}/${interface}_${test_type}_${direction}_${TIMESTAMP}.log"
            if [ -f "$log_file" ]; then
                # Extract throughput from log
                if [ "$test_type" = "TCP" ]; then
                    throughput=$(grep -E "sender|receiver" "$log_file" | tail -1 | awk '{print $(NF-2), $(NF-1)}')
                else
                    throughput=$(grep -E "0.00-${DURATION}" "$log_file" | tail -1 | awk '{print $(NF-2), $(NF-1)}')
                fi
                echo "  ${test_type} ${direction}: ${throughput:-N/A}" >> "$SUMMARY_FILE"
            fi
        done
    done
done

echo "" >> "$SUMMARY_FILE"
echo "Full logs available in: ${LOG_DIR}" >> "$SUMMARY_FILE"

echo "Summary report saved to: ${SUMMARY_FILE}"
EOF
    
    # Make the script executable
    chmod +x "$testing_dir/iperf3_test.sh"
    
    log "iperf3 testing script created and made executable"
}

create_helper_scripts() {
    section "Creating Helper Scripts"
    
    local scripts_dir="$UERANSIM_DIR/scripts"
    mkdir -p "$scripts_dir"
    
    # Start gNB script
    log "Creating gNB startup script..."
    cat > "$scripts_dir/start_gnb.sh" << 'EOF'
#!/bin/bash
# Start UERANSIM gNB

cd "$HOME/UERANSIM"

echo "Starting UERANSIM gNB..."
echo "Press Ctrl+C to stop"
echo "========================"

./build/nr-gnb -c ./config/open5gs-gnb.yaml
EOF
    chmod +x "$scripts_dir/start_gnb.sh"
    
    # Start UE scripts
    log "Creating UE startup scripts..."
    
    cat > "$scripts_dir/start_ue_embb.sh" << 'EOF'
#!/bin/bash
# Start UERANSIM eMBB UE

cd "$HOME/UERANSIM"

echo "Starting UERANSIM eMBB UE..."
echo "Press Ctrl+C to stop"
echo "========================"

./build/nr-ue -c ./config/open5gs-ue-embb.yaml
EOF
    chmod +x "$scripts_dir/start_ue_embb.sh"
    
    cat > "$scripts_dir/start_ue_urllc.sh" << 'EOF'
#!/bin/bash
# Start UERANSIM URLLC UE

cd "$HOME/UERANSIM"

echo "Starting UERANSIM URLLC UE..."
echo "Press Ctrl+C to stop"
echo "========================"

./build/nr-ue -c ./config/open5gs-ue-urllc.yaml
EOF
    chmod +x "$scripts_dir/start_ue_urllc.sh"
    
    cat > "$scripts_dir/start_ue_mmtc.sh" << 'EOF'
#!/bin/bash
# Start UERANSIM mMTC UE

cd "$HOME/UERANSIM"

echo "Starting UERANSIM mMTC UE..."
echo "Press Ctrl+C to stop"
echo "========================"

./build/nr-ue -c ./config/open5gs-ue-mmtc.yaml
EOF
    chmod +x "$scripts_dir/start_ue_mmtc.sh"
    
    # Status check script
    log "Creating status check script..."
    cat > "$scripts_dir/check_status.sh" << 'EOF'
#!/bin/bash
# Check UERANSIM status

echo "UERANSIM Process Status"
echo "======================"

# Check for gNB process
gnb_pid=$(pgrep -f "nr-gnb")
if [ -n "$gnb_pid" ]; then
    echo "✓ gNB is running (PID: $gnb_pid)"
else
    echo "✗ gNB is not running"
fi

# Check for UE processes
ue_pids=$(pgrep -f "nr-ue")
if [ -n "$ue_pids" ]; then
    echo "✓ UE(s) running (PIDs: $ue_pids)"
    echo "  Active UEs:"
    ps -p $ue_pids -o pid,cmd --no-headers | sed 's/.*-c \.\//  - /' | sed 's/\.yaml.*//'
else
    echo "✗ No UEs running"
fi

echo ""
echo "Network Interfaces"
echo "=================="

# Check TUN interfaces
for iface in uesimtun0 uesimtun1 uesimtun3; do
    if ip addr show $iface &>/dev/null; then
        ip_addr=$(ip addr show $iface | grep 'inet ' | awk '{print $2}' | head -1)
        echo "✓ $iface: $ip_addr"
    else
        echo "✗ $iface: not found"
    fi
done
EOF
    chmod +x "$scripts_dir/check_status.sh"
    
    log "Helper scripts created successfully"
}

################################################################################
# Final Setup and Information
################################################################################

final_setup() {
    section "Final Setup and Information"
    
    # Create a README file
    log "Creating setup README..."
    cat > "$UERANSIM_DIR/SETUP_README.md" << 'EOF'
# UERANSIM Installation Complete

This UERANSIM installation includes:

## Directories Structure
- `build/` - Compiled binaries (nr-gnb, nr-ue, nr-binder, nr-cli)
- `config/` - Configuration files for gNB and UEs
- `scripts/` - Helper scripts for starting components
- `testing/` - Testing scripts and log directories

## Configuration Files
- `config/open5gs-gnb.yaml` - gNB configuration with 3 network slices
- `config/open5gs-ue-embb.yaml` - eMBB UE (SST: 1, SD: 000001)
- `config/open5gs-ue-urllc.yaml` - URLLC UE (SST: 2, SD: 000002)
- `config/open5gs-ue-mmtc.yaml` - mMTC UE (SST: 3, SD: 000003)

## Helper Scripts
- `scripts/start_gnb.sh` - Start gNB
- `scripts/start_ue_embb.sh` - Start eMBB UE
- `scripts/start_ue_urllc.sh` - Start URLLC UE
- `scripts/start_ue_mmtc.sh` - Start mMTC UE
- `scripts/check_status.sh` - Check running processes and interfaces

## Testing Scripts
- `testing/iperf3_test.sh` - Comprehensive iperf3 testing script

## Quick Start Commands

### Start gNB (Terminal 1)
```bash
cd ~/UERANSIM
./scripts/start_gnb.sh
# OR manually:
./build/nr-gnb -c ./config/open5gs-gnb.yaml
```

### Start UEs (New terminals)
```bash
# eMBB UE (Terminal 2)
cd ~/UERANSIM && ./scripts/start_ue_embb.sh

# URLLC UE (Terminal 3)
cd ~/UERANSIM && ./scripts/start_ue_urllc.sh

# mMTC UE (Terminal 4)
cd ~/UERANSIM && ./scripts/start_ue_mmtc.sh
```

### Check Status
```bash
cd ~/UERANSIM
./scripts/check_status.sh
```

### Run Performance Tests
```bash
cd ~/UERANSIM/testing
./iperf3_test.sh -s <SERVER_IP>

# Examples:
./iperf3_test.sh -s 192.168.1.100                    # All tests
./iperf3_test.sh -s 192.168.1.100 --tcp-only         # TCP only
./iperf3_test.sh -s 192.168.1.100 --udp-only         # UDP only
./iperf3_test.sh -s 192.168.1.100 -p 4 -t 30 -d 10   # Custom params
```

## Network Slices Configuration

The installation is configured for the following network slices:

1. **eMBB Slice**
   - SST: 1, SD: 000001
   - DNN: `embb.testbed`
   - Interface: `uesimtun0`

2. **URLLC Slice**
   - SST: 2, SD: 000002
   - DNN: `urllc.v2x`
   - Interface: `uesimtun1`

3. **mMTC Slice**
   - SST: 3, SD: 000003
   - DNN: `mmtc.testbed`
   - Interface: `uesimtun3`

## Important Notes

- Ensure your 5G Core (Open5GS) is running and configured for these slices
- Update IP addresses in configuration files if needed (currently set to 127.0.0.1)
- Always start gNB before starting UEs
- Use separate terminals for each component
- Check firewall settings if having connection issues

## Troubleshooting

1. **Build Issues**: Check dependencies are installed correctly
2. **Connection Issues**: Verify 5G Core is running and accessible
3. **Interface Issues**: Check that TUN interfaces are created properly
4. **Performance Issues**: Use the testing scripts to diagnose

For more information, visit: https://github.com/aligungr/UERANSIM
EOF
    
    log "Installation completed successfully!"
    
    echo ""
    echo -e "${PURPLE}========================================="
    echo "🎉 UERANSIM Installation Complete! 🎉"
    echo "=========================================${NC}"
    echo ""
    echo "📍 Installation location: $UERANSIM_DIR"
    echo "📋 Setup guide: $UERANSIM_DIR/SETUP_README.md"
    echo "📊 Log file: $LOG_FILE"
    echo ""
    echo -e "${GREEN}Quick Start:${NC}"
    echo "1. Start gNB: cd $UERANSIM_DIR && ./scripts/start_gnb.sh"
    echo "2. Start UEs: cd $UERANSIM_DIR && ./scripts/start_ue_*.sh"
    echo "3. Check status: cd $UERANSIM_DIR && ./scripts/check_status.sh"
    echo "4. Run tests: cd $UERANSIM_DIR/testing && ./iperf3_test.sh -s <SERVER_IP>"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "- Ensure your 5G Core (Open5GS) is running"
    echo "- Update configuration files if needed"
    echo "- Run the helper scripts to start components"
    echo ""
    echo -e "${BLUE}Happy Testing! 🚀${NC}"
    echo ""
}

################################################################################
# Main Installation Flow
################################################################################

main() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════╗"
    echo "║       UERANSIM Installation Script       ║"
    echo "║                                          ║"
    echo "║  Automated setup from clone to config   ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    pre_check
    install_dependencies
    clone_and_build
    create_gnb_config
    create_ue_configs
    create_testing_scripts
    create_helper_scripts
    final_setup
    
    exit 0
}

# Run main function
main "$@"