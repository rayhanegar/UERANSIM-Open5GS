# Open5GS AMF Docker Container

This directory contains the Dockerfile and configuration files to build and run the Open5GS AMF (Access and Mobility Management Function) as an independent Docker container.

## Prerequisites

- Docker installed and running
- Docker Compose for easier deployment

## Directory Structure

```
amf/
├── Dockerfile              # Simplified Docker image definition for AMF
├── amf.yaml               # Default AMF configuration file  
├── amf-vm.yaml           # VM-accessible AMF configuration
├── DOCKERFILE-CHANGES.md  # Documentation of simplification changes
├── deploy-simple.sh      # Optional deployment script
├── .dockerignore         # Files to exclude from Docker build
└── README.md             # This file
```

## Quick Deployment (Recommended)

### Using Docker Compose (Standard Approach)
```bash
# Go to main containers directory
cd ../

# Start AMF with dependencies
docker compose up -d amf

# View logs
docker compose logs -f amf

# Stop AMF
docker compose stop amf
```

### Alternative: Using Deploy Script
```bash
# If you prefer a script approach
chmod +x deploy-simple.sh
./deploy-simple.sh

# View script options  
./deploy-simple.sh help
```

## Manual Docker Commands (Advanced)

### Building the Docker Image
```bash
# Build from main containers directory
cd ../
docker compose build amf

# Or build directly
docker build -t open5gs-amf:latest ./amf/
```

### Running Container Manually
```bash
# Note: Config is now mounted directly to /etc/open5gs/amf.yaml
docker run -d \
  --name open5gs-amf \
  --network host \
  --cap-add NET_ADMIN \
  -v $(pwd)/amf-vm.yaml:/etc/open5gs/amf.yaml:ro \
  -v $(pwd)/logs:/var/log/open5gs \
  open5gs-amf:latest
```

### Using Docker Compose
```bash
docker-compose up -d amf
```

## Configuration

The AMF configuration can be customized by editing the `amf.yaml` file. The container will use this configuration at startup.

### Key Configuration Parameters

- **SBI Interface**: Port 7777 (HTTP/2)
- **NGAP Interface**: Port 38412 (SCTP)
- **Network**: Custom bridge network (10.10.0.0/24)

## Networking

The container exposes the following ports:
- `38412/sctp`: NGAP interface (N2) for gNB connections
- `7777/tcp`: SBI (Service Based Interface) for 5GC communication

## Logs

Logs are stored in the `./logs` directory on the host machine.

To view logs in real-time:
```bash
docker logs -f open5gs-amf
```

## Health Check

The container includes a health check that verifies the AMF process is running.

Check container health:
```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

## Stopping the Container

```bash
docker stop open5gs-amf
docker rm open5gs-amf
```

Or with Docker Compose:
```bash
docker-compose down
```

## Creating Dockerfiles for Other Network Functions

To create containers for other Open5GS network functions (NRF, SMF, UPF, etc.):

1. Copy this directory structure
2. Replace "amf" with the network function name (e.g., "nrf", "smf")
3. Update the Dockerfile to install the correct package (e.g., `open5gs-nrf`)
4. Adjust exposed ports according to the network function requirements
5. Update the configuration file accordingly

### Example for NRF:
- Package: `open5gs-nrf`
- Config: `nrf.yaml`
- Port: 7777/tcp (SBI)

### Example for SMF:
- Package: `open5gs-smf`
- Config: `smf.yaml`
- Ports: 7777/tcp (SBI), 8805/udp (PFCP for N4), 2123/udp (GTP-C)

### Example for UPF:
- Package: `open5gs-upf`
- Config: `upf.yaml`
- Ports: 8805/udp (PFCP for N4), 2152/udp (GTP-U)

## Troubleshooting

1. **SCTP Connection Issues**: Ensure SCTP kernel module is loaded:
   ```bash
   sudo modprobe sctp
   ```

2. **Permission Denied**: Run with appropriate capabilities:
   ```bash
   --cap-add NET_ADMIN --cap-add SYS_MODULE
   ```

3. **Network Connectivity**: Verify Docker network settings and firewall rules

## Integration with srsRAN

To integrate with srsRAN gNB, ensure:
1. AMF IP address is reachable from gNB
2. NGAP port (38412) is accessible
3. PLMN and TAC configurations match between AMF and gNB
