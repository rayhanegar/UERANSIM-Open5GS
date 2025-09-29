# Standard Docker Compose vs Custom Scripts

## Why Use `docker compose up` Instead of Custom Scripts?

### ✅ **Standard Docker Compose Approach (Recommended)**

```bash
cd open5gs-containers
docker compose up -d amf
docker compose logs -f amf
```

**Benefits:**
- 🚀 **Industry Standard**: Follows Docker best practices
- 🔧 **Built-in Features**: Health checks, dependency management, restart policies
- 📊 **Easy Monitoring**: `docker compose ps`, `docker compose logs`
- 🔄 **Service Management**: Start/stop/restart individual services
- 🌐 **Environment Support**: Built-in environment variable handling
- 📖 **Self-Documenting**: Configuration is visible in docker-compose.yml
- 🔐 **Production Ready**: Used widely in production environments
- 🐛 **Better Debugging**: Direct container interaction with `docker compose exec`

### ❌ **Custom Script Approach (Not Recommended)**

```bash
./deploy-vm-accessible.sh
```

**Limitations:**
- 🛠️ **Maintenance Overhead**: Custom scripts need updates and debugging
- 📚 **Documentation Burden**: Need to document script behavior separately
- 🔍 **Hidden Logic**: Configuration details buried in script code
- 🐛 **Error Prone**: Custom logic can introduce bugs
- 👥 **Team Friction**: New team members need to learn custom tooling
- 🔄 **Reinventing Wheel**: Duplicating functionality Docker Compose provides
- 📦 **Not Portable**: Scripts may not work across different environments

## Current Configuration Status

Your setup is **already optimized** for standard Docker Compose usage:

### ✅ **docker-compose.yml** (Main containers directory)
```yaml
amf:
  build:
    context: ./amf
    dockerfile: Dockerfile
  ports:
    - "0.0.0.0:38412:38412/sctp"  # VM accessible
    - "0.0.0.0:7705:7777/tcp"     # VM accessible
    - "0.0.0.0:9005:9090/tcp"     # VM accessible  
  volumes:
    - ./amf/amf-vm.yaml:/etc/open5gs/amf.yaml:ro  # Direct mount
```

### ✅ **Dockerfile** (AMF directory)
```dockerfile
# Simple, direct binary execution
CMD ["/usr/bin/open5gs-amfd", "-c", "/etc/open5gs/amf.yaml"]
```

## Recommended Workflow

### Development
```bash
cd open5gs-containers

# Start dependencies
docker compose up -d mongodb nrf scp

# Start and test AMF  
docker compose up -d amf
docker compose logs -f amf

# Make config changes
vim amf/amf-vm.yaml

# Restart to apply changes
docker compose restart amf
```

### Production
```bash
# Deploy all services
docker compose up -d

# Monitor health
docker compose ps
watch 'docker compose ps --format "table {{.Name}}\t{{.Status}}"'

# View aggregated logs
docker compose logs -f --tail=100
```

### Debugging
```bash
# Check individual service
docker compose ps amf
docker compose logs amf

# Execute commands in container
docker compose exec amf bash
docker compose exec amf netstat -tuln

# Test configuration
docker compose config --services
docker compose config amf
```

## Migration Path

If you have existing custom scripts:

1. **Keep docker-compose.yml** ✅ (already done)
2. **Remove custom scripts** ❌ (or keep as backup only)
3. **Update documentation** ✅ (already done)
4. **Train team on standard commands** 📖

## Summary

**Use `docker compose up -d amf`** because:

1. ✅ **It's the standard approach** everyone knows
2. ✅ **Your configuration is already optimized for it**
3. ✅ **No custom scripts to maintain**
4. ✅ **Built-in features for production use**
5. ✅ **Better integration with Docker ecosystem**

The custom deployment scripts can be removed or kept as optional alternatives, but the primary deployment method should be standard Docker Compose commands.