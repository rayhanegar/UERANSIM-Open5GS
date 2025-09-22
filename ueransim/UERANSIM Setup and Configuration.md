# UERANSIM Installation
## Clone Repository
```warp-runnable-command
cd ~
git clone https://github.com/aligungr/UERANSIM
cd UERANSIM
```
## Requirements
```warp-runnable-command
sudo apt update
sudo apt upgrade
sudo apt install make gcc g++ libsctp-dev lkstcp-tools iproute2
sudo snap install cmake --classic
```
## Building
```warp-runnable-command
cd ~/UERANSIM
sudo make -j ${nproc}
cd ~/UERANSIM/build
```
# UERANSIM Configuration
## UERANSIM gNB Configuration
```warp-runnable-command
cd ~/UERANSIM/build/
sudo nano open5gs-gnb.yaml
```
### open5gs\-gnb\.yaml
```yaml
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
    # dnn: 'embb.testbed'
  - sst: 2
    # dnn: 'urllc.v2x'
  - sst: 3
    # dnn: 'mmtc.testbed'

# Indicates whether or not SCTP stream number errors should be ignored.
ignoreStreamIds: true
```
## UERANSIM UE Configuration
### Instantiation
Instantiate three UEs\, each representing different network slices\.
```warp-runnable-command
cd ~/UERANSIM/build/
sudo touch open5gs-ue-embb.yaml open5gs-ue-urllc.yaml open5gs-ue-mmtc.yaml
```
#### open5gs\-ue\-embb\.yaml
```yaml
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

# Configured NSSAI for this UE by HPLMN
configured-nssai:
  - sst: 1

# Default Configured NSSAI for this UE
default-nssai:
  - sst: 1
    sd: 1

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
```
#### open5gs\-ue\-urllc\.yaml
```yaml
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

# Configured NSSAI for this UE by HPLMN
configured-nssai:
  - sst: 2

# Default Configured NSSAI for this UE
default-nssai:
  - sst: 2
    sd: 2

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
```
#### open5gs\-ue\-mmtc\.yaml
```yaml
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

# Configured NSSAI for this UE by HPLMN
configured-nssai:
  - sst: 3

# Default Configured NSSAI for this UE
default-nssai:
  - sst: 3
    sd: 3

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
```
# Running UERANSIM
## Running UERANSIM gNB
```warp-runnable-command
cd ~/UERANSIM
./build/nr-gnb -c ./config/open5gs-gnb.yaml
```
## Running UERANSIM uE\(s\)
```warp-runnable-command
# On a terminal
cd ~/UERANSIM
./build/nr-ue -c ./config/open5gs-ue-embb.yaml

# On a new terminal
cd ~/UERANSIM
./build/nr-ue -c ./config/open5gs-ue-urllc.yaml

# On a new terminal
cd ~/UERANSIM
./build/nr-ue -c ./config/open5gs-ue-mmtc.yaml
```
# Utility Scripts
```warp-runnable-command
cd ~/UERANSIM/testing
mkdir testing_logs
sudo nano ./iperf3_test.sh
```
Inside the iperf3\_test\.sh\, put the following scripts\.
```warp-runnable-command
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
LOG_DIR="/home/rayhan/UERANSIM/testing/testing_logs"

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
```
# Install Scripts
Customized installation scripts for you \<3