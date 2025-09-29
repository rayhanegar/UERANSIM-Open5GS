# Simplified AMF Dockerfile - Changes Summary

## What Changed

### Before (Complex Startup Script)
- Used a bash wrapper script with signal handling
- Checked for custom config files in `/etc/open5gs/custom/`
- Copied config files during startup
- Complex entrypoint with background process management

### After (Direct Binary Execution)
- Runs the Open5GS AMF binary directly
- Configuration file mounted directly to `/etc/open5gs/amf.yaml`
- No intermediate scripts or config copying
- Simple `CMD` instruction

## Benefits of Simplified Approach

1. **Faster Startup**: No script overhead, direct binary execution
2. **Better Signal Handling**: Docker handles process signals directly
3. **Simpler Debugging**: Direct logs from the AMF process
4. **Reduced Complexity**: Fewer moving parts, easier to troubleshoot
5. **Standard Docker Pattern**: Follows Docker best practices

## File Changes

### Dockerfile Changes
```dockerfile
# REMOVED: Complex startup script creation
# REMOVED: Custom config path handling

# ADDED: Simple comment about config mounting
# CHANGED: ENTRYPOINT → CMD with direct binary execution
CMD ["/usr/bin/open5gs-amfd", "-c", "/etc/open5gs/amf.yaml"]
```

### Docker-Compose Changes
```yaml
volumes:
  # CHANGED: Direct config mounting (no custom path)
  - ./amf/amf-vm.yaml:/etc/open5gs/amf.yaml:ro

ports:
  # IMPROVED: 0.0.0.0 binding for VM accessibility
  - "0.0.0.0:38412:38412/sctp"
  - "0.0.0.0:7705:7777/tcp"
  - "0.0.0.0:9005:9090/tcp"
```

## Usage

### Deploy with Main Docker-Compose
```bash
cd /path/to/open5gs-containers
docker-compose build amf
docker-compose up -d amf
```

### Deploy with Simple Script
```bash
cd /path/to/amf/
./deploy-simple.sh
```

### View Logs
```bash
docker logs open5gs-amf -f
```

## Configuration Requirements

1. **Config File**: Must be present at `./amf/amf-vm.yaml` (relative to docker-compose.yml)
2. **Network Binding**: Config should bind to `0.0.0.0` for VM accessibility
3. **Port Mapping**: Docker handles port forwarding from host to container

## Troubleshooting

### Container Won't Start
```bash
# Check if config file exists and is valid
docker run --rm -v $(pwd)/amf-vm.yaml:/etc/open5gs/amf.yaml open5gs-amf:latest /usr/bin/open5gs-amfd -c /etc/open5gs/amf.yaml -h

# Check container logs
docker logs open5gs-amf
```

### NGAP Not Accessible
1. Verify config binds to `0.0.0.0:38412`
2. Check host firewall rules
3. Confirm port mapping: `0.0.0.0:38412:38412/sctp`

### Process Not Starting
1. Check AMF binary path: `/usr/bin/open5gs-amfd`
2. Verify config file syntax
3. Check dependencies (MongoDB, other NFs)

## Migration from Old Approach

If you have existing deployments with the complex startup script:

1. **Update Dockerfile**: Remove startup script, use direct CMD
2. **Update docker-compose.yml**: Change volume mount path
3. **Rebuild containers**: `docker-compose build amf`
4. **Restart services**: `docker-compose up -d amf`

The configuration file content remains the same, only the mounting path changes.