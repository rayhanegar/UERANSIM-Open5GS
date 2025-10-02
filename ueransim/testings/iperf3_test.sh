#!/bin/bash

# UERANSIM iperf3 Testing Script
# Tests uesimtun0, uesimtun1, and uesimtun2 interfaces
# Supports TCP/UDP, uplink/downlink, parallel streams, and duration

# Default values
SERVER=""
PARALLEL=1
DURATION=10
BUFFER_SIZE="128K"
DELAY_BETWEEN_TESTS=5
TCP_ONLY=false
UDP_ONLY=false
USER=$(whoami)

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
LOG_DIR="/home/${USER}/UERANSIM-Open5GS/ueransim/testings/testing_logs"

# Test interfaces
INTERFACES=("uesimtun0" "uesimtun1" "uesimtun2")

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
    cmd="/home/${USER}/UERANSIM-Open5GS/ueransim/build/nr-binder ${interface} iperf3 -c ${SERVER} -P ${PARALLEL} -t ${DURATION} -w ${BUFFER_SIZE}"
    
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
