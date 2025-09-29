# Open5GS Container Deployment - Standard Docker Compose

This guide shows how to deploy Open5GS containers using standard `docker compose` commands without custom scripts.

## Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Configuration files present in each service directory (amf/amf-vm.yaml, etc.)

### Deploy AMF Only
```bash
# Navigate to containers directory
cd open5gs-containers

# Build and start AMF with dependencies
docker compose up -d amf

# View AMF logs
docker compose logs -f amf
```

### Deploy Full 5G Core
```bash
# Start all services
docker compose up -d

# View logs for all services
docker compose logs -f

# View logs for specific service
docker compose logs -f amf
```

## Common Commands

### Service Management
```bash
# Start specific service
docker compose up -d <service-name>

# Stop specific service
docker compose stop <service-name>

# Restart service
docker compose restart <service-name>

# Remove service (stops and removes container)
docker compose rm -f <service-name>
```

### Build and Update
```bash
# Rebuild specific service
docker compose build <service-name>

# Rebuild and restart
docker compose up -d --build <service-name>

# Pull latest base images and rebuild
docker compose build --pull <service-name>
```

### Monitoring
```bash
# View service status
docker compose ps

# View service logs (follow)
docker compose logs -f <service-name>

# View logs with timestamps
docker compose logs -f -t <service-name>

# View last N lines of logs
docker compose logs --tail=50 <service-name>
```

### Cleanup
```bash
# Stop all services
docker compose down

# Stop and remove volumes
docker compose down -v

# Stop, remove containers, networks, and images
docker compose down --rmi all -v
```

## Service Names

The following services are available in the docker-compose.yml:

### Core Services
- `mongodb` - Database
- `nrf` - Network Repository Function
- `scp` - Service Communication Proxy

### Network Functions
- `amf` - Access and Mobility Management Function
- `smf` - Session Management Function  
- `upf` - User Plane Function
- `ausf` - Authentication Server Function
- `udm` - Unified Data Management
- `udr` - Unified Data Repository
- `pcf` - Policy Control Function
- `nssf` - Network Slice Selection Function
- `bsf` - Binding Support Function

### Legacy 4G Functions
- `mme` - Mobility Management Entity
- `hss` - Home Subscriber Server
- `pcrf` - Policy and Charging Rules Function
- `sgwc` - Serving Gateway Control Plane
- `sgwu` - Serving Gateway User Plane

## Configuration

### AMF VM Accessibility
The AMF is configured for VM-to-VM communication:

```yaml
ports:
  - "0.0.0.0:38412:38412/sctp"  # NGAP - accessible from other VMs
  - "0.0.0.0:7705:7777/tcp"     # SBI - accessible from other VMs  
  - "0.0.0.0:9005:9090/tcp"     # Metrics - accessible from other VMs

volumes:
  - ./amf/amf-vm.yaml:/etc/open5gs/amf.yaml:ro
```

### Required Configuration Files
Ensure these configuration files exist:
- `amf/amf-vm.yaml` - AMF configuration with 0.0.0.0 binding
- `smf/smf.yaml` - SMF configuration
- `upf/upf.yaml` - UPF configuration
- Other NF configurations as needed

## Networking

### Internal Network
- Network: `5gcore` (10.10.0.0/24)
- AMF IP: 10.10.0.5 (internal)
- Host ports: 38412 (NGAP), 7705 (SBI), 9005 (Metrics)

### External Access
From other VMs, connect to:
- **NGAP**: `<host-vm-ip>:38412` (for gNB)
- **SBI**: `http://<host-vm-ip>:7705` (for other NFs)
- **Metrics**: `http://<host-vm-ip>:9005/metrics`

## Development Workflow

### Typical Development Cycle
```bash
# 1. Modify configuration
vim amf/amf-vm.yaml

# 2. Restart service to pick up changes
docker compose restart amf

# 3. View logs to verify changes
docker compose logs -f amf

# 4. If Dockerfile changed, rebuild
docker compose up -d --build amf
```

### Debugging
```bash
# Check service health
docker compose ps

# Get detailed service info
docker compose config amf

# Execute commands in running container
docker compose exec amf bash

# Check network connectivity
docker compose exec amf ping mongodb
```

## Environment Variables

You can use environment variables for dynamic configuration:

```bash
# Set custom host IP
export HOST_IP=192.168.1.100
docker compose up -d amf

# Set custom MCC/MNC
export PLMN_MCC=001
export PLMN_MNC=01
docker compose up -d amf
```

## Production Deployment

### Recommended Production Setup
```bash
# Use specific image tags
docker compose build
docker tag open5gs-amf:latest open5gs-amf:v2.7.0

# Deploy with restart policies
docker compose up -d --no-build

# Monitor logs
docker compose logs -f --tail=100
```

### Health Monitoring
```bash
# Check all service health
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

# Automated health check
watch 'docker compose ps | grep -E "(healthy|unhealthy)"'
```

## Troubleshooting

### Common Issues

1. **AMF not accessible from other VMs**
   ```bash
   # Check port binding
   netstat -tuln | grep -E '(38412|7705)'
   
   # Verify container is running
   docker compose ps amf
   
   # Check firewall
   sudo iptables -L -n | grep -E '(38412|7705)'
   ```

2. **Configuration not loading**
   ```bash
   # Verify config file exists
   ls -la amf/amf-vm.yaml
   
   # Check config is mounted correctly
   docker compose exec amf cat /etc/open5gs/amf.yaml
   ```

3. **Service dependency issues**
   ```bash
   # Start dependencies first
   docker compose up -d mongodb nrf scp
   
   # Then start AMF
   docker compose up -d amf
   ```

### Log Analysis
```bash
# Find errors in logs
docker compose logs amf | grep -i error

# Search for specific patterns
docker compose logs amf | grep -i "ngap\|sctp"

# Get logs with context
docker compose logs --since=1h amf
```

## Summary

Using `docker compose` directly is the recommended approach because:
- ✅ Standard Docker workflow
- ✅ No custom scripts to maintain  
- ✅ Built-in dependency management
- ✅ Easy service scaling and management
- ✅ Integrated logging and monitoring
- ✅ Environment variable support
- ✅ Production-ready patterns

The configuration is already optimized for VM accessibility with proper port binding and direct config mounting.