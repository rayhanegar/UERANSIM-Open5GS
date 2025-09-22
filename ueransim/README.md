# UERANSIM Installation and Configuration Guide

This repository contains a comprehensive setup guide and installation script for **UERANSIM** - an open-source 5G UE and RAN (gNodeB) simulator with **3 Network Slice** support for integration with **Open5GS 5G Core Network**.

## 🎯 Features

- **Complete 5G RAN Simulation**: gNodeB and multiple UE simulation
- **3 Network Slice Support**: eMBB, URLLC, mMTC slice testing
- **Open5GS Integration**: Pre-configured for seamless core network connection
- **Automated Installation**: One-script deployment with all dependencies
- **Performance Testing**: Built-in iperf3 testing across all network slices
- **Production Ready**: Comprehensive logging and error handling

## 📋 Network Slice Configuration

| Slice | SST | IMSI Pattern | DNN | Description | Use Cases |
|-------|-----|--------------|-----|-------------|-----------|
| **eMBB** | 1 | 001011xxxxxx | embb.testbed | Enhanced Mobile Broadband | Video streaming, file downloads, web browsing |
| **URLLC** | 2 | 001012xxxxxx | urllc.v2x | Ultra-Reliable Low-Latency | Autonomous vehicles, industrial automation, AR/VR |
| **mMTC** | 3 | 001013xxxxxx | mmtc.testbed | Massive Machine-Type Communication | IoT sensors, smart city, environmental monitoring |

## 🚀 Quick Start

### Prerequisites

- Ubuntu 20.04 LTS or later
- Root/sudo access
- 4GB+ RAM (8GB recommended for multiple UEs)
- **Open5GS 5G Core** running (see [Open5GS README](../open5gs/README.md))

### One-Command Installation

```bash
./install_ueransim.sh --all
```

This will:
1. Install all build dependencies (make, gcc, g++, cmake, libsctp-dev)
2. Clone and compile UERANSIM from source
3. Generate gNB and UE configuration files for 3 network slices
4. Create performance testing scripts
5. Set up logging and monitoring utilities

## 📖 Usage Options

### Basic Commands

```bash
# Complete installation and configuration
./install_ueransim.sh --all

# Install dependencies and build only
./install_ueransim.sh --build

# Generate configuration files only
./install_ueransim.sh --config

# Create testing scripts only
./install_ueransim.sh --testing

# Show installation status
./install_ueransim.sh --status

# Clean installation
./install_ueransim.sh --clean

# Show help
./install_ueransim.sh --help
```

### Manual Step-by-Step Installation

```bash
# Step 1: Install dependencies and build UERANSIM
./install_ueransim.sh --build

# Step 2: Generate slice-specific configurations
./install_ueransim.sh --config

# Step 3: Create testing and utility scripts
./install_ueransim.sh --testing
```

## 🛠️ What Gets Installed

### Core Components
- **Build Tools**: gcc, g++, make, cmake
- **Network Libraries**: libsctp-dev, lksctp-tools, iproute2
- **UERANSIM Source**: Latest version from GitHub
- **Compiled Binaries**: nr-gnb, nr-ue, nr-binder

### Configuration Files
- **gNB Configuration**: `open5gs-gnb.yaml`
- **UE Configurations**: 
  - `open5gs-ue-embb.yaml` (eMBB slice)
  - `open5gs-ue-urllc.yaml` (URLLC slice) 
  - `open5gs-ue-mmtc.yaml` (mMTC slice)

### Testing Scripts
- **Performance Testing**: `iperf3_test.sh`
- **Network Monitoring**: Interface and connectivity checks
- **Logging Utilities**: Comprehensive test result collection

## 🔧 Configuration Details

### gNB Configuration (`open5gs-gnb.yaml`)

```yaml
mcc: '001'          # Mobile Country Code
mnc: '01'           # Mobile Network Code
nci: '0x000000010'  # NR Cell Identity
tac: 1              # Tracking Area Code

# Network interfaces (localhost for single-host setup)
linkIp: 127.0.0.1   # Radio Link Simulation
ngapIp: 127.0.0.1   # N2 Interface (AMF connection)
gtpIp: 127.0.0.1    # N3 Interface (UPF connection)

# AMF connection
amfConfigs:
  - address: 127.0.0.5  # Open5GS AMF address
    port: 38412

# Supported network slices
slices:
  - sst: 1  # eMBB
  - sst: 2  # URLLC
  - sst: 3  # mMTC
```

### UE Configurations

Each UE is configured for a specific network slice:

#### eMBB UE (`open5gs-ue-embb.yaml`)
```yaml
supi: 'imsi-001011000000001'  # eMBB IMSI pattern
sessions:
  - type: 'IPv4'
    apn: 'embb.testbed'
    slice:
      sst: 1
configured-nssai:
  - sst: 1
```

#### URLLC UE (`open5gs-ue-urllc.yaml`)
```yaml
supi: 'imsi-001012000000001'  # URLLC IMSI pattern
sessions:
  - type: 'IPv4'
    apn: 'urllc.v2x'
    slice:
      sst: 2
configured-nssai:
  - sst: 2
```

#### mMTC UE (`open5gs-ue-mmtc.yaml`)
```yaml
supi: 'imsi-001013000000001'  # mMTC IMSI pattern
sessions:
  - type: 'IPv4'
    apn: 'mmtc.testbed'
    slice:
      sst: 3
configured-nssai:
  - sst: 3
```

## 🚦 Running UERANSIM

### Prerequisites Check

1. **Verify Open5GS is running**:
   ```bash
   sudo systemctl status open5gs-amfd open5gs-upfd
   ```

2. **Check network interfaces**:
   ```bash
   ip addr show | grep ogstun
   ```

3. **Verify subscriber data** in Open5GS WebUI (http://localhost:9999):
   - Add subscribers with IMSI: 001011000000001, 001012000000001, 001013000000001
   - Use default key: 465B5CE8B199B49FAA5F0A2EE238A6BC
   - Use default OP: E8ED289DEBA952E4283B54E88E6183CA

### Start gNodeB

```bash
cd ~/UERANSIM
sudo ./build/nr-gnb -c config/open5gs-gnb.yaml
```

**Expected Output**:
```
UERANSIM v3.2.6
[2025-09-22 10:00:00.000] [sctp] [info] Trying to establish SCTP connection... (127.0.0.5:38412)
[2025-09-22 10:00:00.001] [sctp] [info] SCTP connection established (127.0.0.5:38412)
[2025-09-22 10:00:00.001] [ngap] [debug] Sending NG Setup Request
[2025-09-22 10:00:00.002] [ngap] [debug] NG Setup Response received
[2025-09-22 10:00:00.002] [ngap] [info] NG Setup procedure is successful
```

### Start UEs (Multiple Terminals)

#### Terminal 1 - eMBB UE
```bash
cd ~/UERANSIM
sudo ./build/nr-ue -c config/open5gs-ue-embb.yaml
```

#### Terminal 2 - URLLC UE
```bash
cd ~/UERANSIM
sudo ./build/nr-ue -c config/open5gs-ue-urllc.yaml
```

#### Terminal 3 - mMTC UE
```bash
cd ~/UERANSIM
sudo ./build/nr-ue -c config/open5gs-ue-mmtc.yaml
```

**Expected UE Output**:
```
UERANSIM v3.2.6
[2025-09-22 10:00:10.000] [nas] [info] UE switches to state [MM-DEREGISTERED/PLMN-SEARCH]
[2025-09-22 10:00:10.001] [rrc] [debug] New signal detected for cell[1], total [1] cells in coverage
[2025-09-22 10:00:10.001] [nas] [info] Selected plmn[001/01]
[2025-09-22 10:00:10.002] [rrc] [info] Selected cell plmn[001/01] tac[1] category[SUITABLE]
[2025-09-22 10:00:10.002] [nas] [info] UE switches to state [MM-DEREGISTERED/PS]
[2025-09-22 10:00:10.002] [nas] [info] UE switches to state [MM-REGISTERED/NORMAL-SERVICE]
[2025-09-22 10:00:10.002] [nas] [debug] Initial registration is successful
[2025-09-22 10:00:10.002] [nas] [debug] Initial PDU sessions are establishing [1#]
[2025-09-22 10:00:10.003] [nas] [info] UE switches to state [CM-CONNECTED]
[2025-09-22 10:00:10.020] [nas] [info] PDU Session establishment accept
```

### Verify Connectivity

After successful registration, each UE creates a TUN interface:

```bash
# Check UE interfaces
ip addr show | grep uesimtun

# Expected output:
# uesimtun0: eMBB UE interface (10.45.0.x)
# uesimtun1: URLLC UE interface (10.45.1.x)
# uesimtun3: mMTC UE interface (10.45.2.x)
```

### Test Internet Connectivity

```bash
# Test eMBB slice
ping -I uesimtun0 google.com

# Test URLLC slice
ping -I uesimtun1 google.com

# Test mMTC slice  
ping -I uesimtun3 google.com
```

## 📊 Performance Testing

### Automated iperf3 Testing

The installation includes a comprehensive testing script:

```bash
cd ~/UERANSIM/testing

# Start iperf3 server (on another machine or different terminal)
iperf3 -s

# Run comprehensive tests across all slices
sudo ./iperf3_test.sh -s SERVER_IP

# Advanced testing options
sudo ./iperf3_test.sh -s SERVER_IP -p 4 -t 30 -d 3    # 4 streams, 30s duration
sudo ./iperf3_test.sh -s SERVER_IP --tcp-only         # TCP only
sudo ./iperf3_test.sh -s SERVER_IP --udp-only         # UDP only
```

### Manual Performance Testing

#### TCP Throughput Test
```bash
# eMBB slice (high throughput expected)
cd ~/UERANSIM
./build/nr-binder uesimtun0 iperf3 -c SERVER_IP -t 10 -P 4

# URLLC slice (low latency focus)
./build/nr-binder uesimtun1 iperf3 -c SERVER_IP -t 10

# mMTC slice (optimized for many small connections)
./build/nr-binder uesimtun3 iperf3 -c SERVER_IP -t 10 -l 64
```

#### UDP Latency Test
```bash
# URLLC slice latency test
./build/nr-binder uesimtun1 iperf3 -c SERVER_IP -u -b 10M -t 10

# Real-time application simulation
./build/nr-binder uesimtun1 iperf3 -c SERVER_IP -u -b 1M -l 64 -t 60
```

#### Custom Application Testing
```bash
# Use specific slice for custom applications
./build/nr-binder uesimtun0 curl -w "@curl-format.txt" https://example.com
./build/nr-binder uesimtun1 wget --bind-address=$(ip addr show uesimtun1 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1) https://example.com
```

## 🔍 Monitoring and Troubleshooting

### Log Locations
```bash
# UERANSIM runtime logs
~/UERANSIM/logs/

# Installation logs
/tmp/ueransim_install_*.log

# Performance test logs
~/UERANSIM/testing/testing_logs/
```

### Check Service Status
```bash
# Check if gNB is running
ps aux | grep nr-gnb

# Check UE processes
ps aux | grep nr-ue

# Monitor network interfaces
watch -n 1 'ip addr show | grep uesimtun'
```

### Common Issues and Solutions

#### 1. **gNB Cannot Connect to AMF**
```bash
# Check AMF is running
sudo systemctl status open5gs-amfd

# Verify AMF address in config
grep -A 2 "amfConfigs:" ~/UERANSIM/config/open5gs-gnb.yaml

# Check firewall
sudo iptables -L | grep 38412
```

#### 2. **UE Registration Failed**
```bash
# Verify subscriber in Open5GS WebUI
# Check IMSI, Key, OP values match configuration

# Check UE logs for authentication errors
tail -f ~/UERANSIM/logs/ue-*.log
```

#### 3. **No Internet Connectivity**
```bash
# Check Open5GS UPF is running
sudo systemctl status open5gs-upfd

# Verify TUN interfaces in Open5GS
ip addr show ogstun ogstun2 ogstun3

# Check iptables rules
sudo iptables -t nat -L POSTROUTING
```

#### 4. **Performance Issues**
```bash
# Check CPU usage
htop

# Monitor network interfaces
iftop -i uesimtun0

# Check for packet loss
ping -I uesimtun0 -c 100 8.8.8.8 | grep loss
```

### Debug Mode

Enable debug logging for detailed troubleshooting:

```bash
# Run gNB with debug logs
cd ~/UERANSIM
sudo ./build/nr-gnb -c config/open5gs-gnb.yaml --log-level debug

# Run UE with debug logs
sudo ./build/nr-ue -c config/open5gs-ue-embb.yaml --log-level debug
```

## 📚 Directory Structure

```
~/UERANSIM/
├── build/                    # Compiled binaries
│   ├── nr-gnb               # gNodeB simulator
│   ├── nr-ue                # UE simulator
│   └── nr-binder            # Network namespace binder
├── config/                   # Configuration files
│   ├── open5gs-gnb.yaml     # gNB configuration
│   ├── open5gs-ue-embb.yaml # eMBB UE configuration
│   ├── open5gs-ue-urllc.yaml# URLLC UE configuration
│   └── open5gs-ue-mmtc.yaml # mMTC UE configuration
├── testing/                  # Testing utilities
│   ├── iperf3_test.sh       # Automated performance testing
│   └── testing_logs/        # Test result logs
├── logs/                     # Runtime logs
└── src/                      # Source code
```

## 🔐 Security Considerations

- **Default Authentication**: Uses default 5G test keys - change for production
- **Local Setup**: Configured for localhost testing - adjust for distributed deployment
- **Root Privileges**: Requires sudo for TUN interface creation
- **Network Isolation**: Each slice creates separate TUN interfaces

## 📈 Performance Expectations

### Expected Throughput (Single Host)
| Slice | TCP Downlink | TCP Uplink | UDP | Latency |
|-------|--------------|------------|-----|---------|
| **eMBB** | 100-500 Mbps | 100-500 Mbps | 100+ Mbps | 10-50ms |
| **URLLC** | 50-200 Mbps | 50-200 Mbps | 50+ Mbps | 1-10ms |
| **mMTC** | 10-100 Mbps | 10-100 Mbps | 10+ Mbps | 10-100ms |

*Note: Performance depends on system resources and network configuration*

## 🤝 Integration with Open5GS

### Subscriber Management

Add subscribers via Open5GS WebUI (http://localhost:9999):

| Field | eMBB UE | URLLC UE | mMTC UE |
|-------|---------|----------|---------|
| **IMSI** | 001011000000001 | 001012000000001 | 001013000000001 |
| **Key** | 465B5CE8B199B49FAA5F0A2EE238A6BC | (same) | (same) |
| **OP** | E8ED289DEBA952E4283B54E88E6183CA | (same) | (same) |
| **APN** | embb.testbed | urllc.v2x | mmtc.testbed |

### Network Slice Template (NST)

The configuration supports 3GPP-compliant network slicing:

```yaml
# eMBB Slice (S-NSSAI: SST=1)
- Enhanced Mobile Broadband
- High throughput, moderate latency
- Video streaming, file downloads

# URLLC Slice (S-NSSAI: SST=2) 
- Ultra-Reliable Low-Latency Communication
- Low latency, high reliability
- Autonomous driving, industrial automation

# mMTC Slice (S-NSSAI: SST=3)
- Massive Machine-Type Communication  
- High device density, low power
- IoT sensors, smart city applications
```

## 🔗 References

- [UERANSIM GitHub Repository](https://github.com/aligungr/UERANSIM)
- [Open5GS Integration Guide](../open5gs/README.md)
- [3GPP 5G System Architecture](https://www.3gpp.org/technologies/5g-system-overview)
- [5G Network Slicing Standards](https://www.3gpp.org/specifications-technologies/specifications-by-series)

## 📞 Support

For technical support:

1. **Check Installation Logs**: `/tmp/ueransim_install_*.log`
2. **Review UERANSIM Logs**: `~/UERANSIM/logs/`
3. **Verify Open5GS Status**: All core network functions running
4. **Test Basic Connectivity**: Ping tests through each slice
5. **Check GitHub Issues**: [UERANSIM Issues](https://github.com/aligungr/UERANSIM/issues)

## 🆘 Quick Troubleshooting Commands

```bash
# Check overall system status
./install_ueransim.sh --status

# Restart all UERANSIM components
sudo pkill nr-gnb nr-ue
cd ~/UERANSIM
sudo ./build/nr-gnb -c config/open5gs-gnb.yaml &
sudo ./build/nr-ue -c config/open5gs-ue-embb.yaml &

# Test basic connectivity
ping -I uesimtun0 -c 4 8.8.8.8

# Check performance
cd ~/UERANSIM/testing
sudo ./iperf3_test.sh -s YOUR_SERVER_IP
```

---

**Last Updated**: September 22, 2025  
**Version**: 1.0  
**Compatibility**: UERANSIM v3.2.6+, Open5GS v2.4+  
**Author**: Rayhan Egar - Digital Hugs