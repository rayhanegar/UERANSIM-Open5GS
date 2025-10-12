# Open5GS K3s Quick Reference

## Current Deployment Status
✅ **8/9 NFs Running** (Control Plane + AMF)
- NRF, SCP, UDR, UDM, AUSF, PCF, NSSF, AMF

⏳ **Pending:** SMF, UPF

## Key Configurations

### MongoDB
- **Connection:** `mongodb://mongodb:27017/open5gs`
- **No Authentication:** Matches bare metal setup
- **External Endpoint:** `192.168.50.200:27017`

### AMF NGAP
- **Internal Port:** 38412
- **NodePort (External):** 30412 ⚠️ **Use this for UERANSIM!**
- **Node IP:** 192.168.50.200

### PLMN
- **MCC:** 001
- **MNC:** 01

### DNNs
- `embb.testbed` (SST: 1)
- `urllc.v2x` (SST: 2)
- `mmtc.testbed` (SST: 3)

## Quick Commands

```bash
# View all pods
kubectl get pods -n open5gs

# Watch pods live
kubectl get pods -n open5gs -w

# Check pod logs
kubectl logs <pod-name> -n open5gs -f

# Restart a pod
kubectl delete pod <pod-name> -n open5gs

# Complete redeployment
./redeploy-k3s.sh

# Build and import containers
./build-import-containers.sh

# View services
kubectl get svc -n open5gs

# Check AMF external access
kubectl get svc amf -n open5gs
```

## UERANSIM Configuration

### gNB Config Update Required
```yaml
amfConfigs:
  - address: 192.168.50.200  # K3s node IP
    port: 30412  # NodePort (was 38412)
    
linkIp: <gnb-ip>     # gNB bind address
ngapIp: <gnb-ip>     # NGAP signaling
gtpIp: <gnb-ip>      # GTP data plane
```

### UE Config
```yaml
supi: 'imsi-001010000000001'
mcc: '001'
mnc: '01'
key: '465B5CE8B199B49FAA5F0A2EE238A6BC'
op: 'E8ED289DEBA952E4283B54E88E6183CA'
opType: 'OPC'
amf: '8000'
imei: '356938035643803'

# DNN configuration
sessions:
  - type: 'IPv4'
    apn: 'embb.testbed'  # or urllc.v2x or mmtc.testbed
    slice:
      sst: 1  # Match DNN SST
```

## Log Locations

### Host Logs
```
/mnt/data/open5gs-logs/
├── nrf/nrf.log
├── scp/scp.log
├── udr/udr.log
├── udm/udm.log
├── ausf/ausf.log
├── pcf/pcf.log
├── nssf/nssf.log
└── amf/amf.log
```

### In-Pod Logs
```
/var/log/open5gs/<nf>.log
```

## Troubleshooting

### Pod Won't Start
```bash
# Check events
kubectl describe pod <pod-name> -n open5gs

# Check logs
kubectl logs <pod-name> -n open5gs --previous

# Check config
kubectl get cm <nf>-config -n open5gs -o yaml
```

### MongoDB Issues
```bash
# Test from cluster
kubectl run test --rm -it --image=mongo:5.0 -n open5gs -- \
  mongo mongodb://mongodb:27017/open5gs --eval "db.stats()"

# Test from host
mongo mongodb://192.168.50.200:27017/open5gs --eval "db.stats()"
```

### Service Not Accessible
```bash
# Check service
kubectl get svc -n open5gs

# Check endpoints
kubectl get endpoints -n open5gs

# Test internal connectivity
kubectl run test --rm -it --image=busybox -n open5gs -- \
  wget -O- http://nrf.open5gs.svc.cluster.local:7777
```

## Important Files

- `deploy-k3s.sh` - Initial deployment
- `redeploy-k3s.sh` - Clean redeploy
- `build-import-containers.sh` - Build containers
- `verify-mongodb.sh` - MongoDB connectivity test

## Common Issues Fixed

1. ✅ MongoDB auth mismatch → Removed authentication
2. ✅ UDM config typo → Fixed section name
3. ✅ AMF YAML indentation → Fixed structure  
4. ✅ AMF NGAP bind → Changed to 0.0.0.0
5. ✅ AMF NodePort → Changed 38412 → 30412

## Documentation

- `DEPLOYMENT-SUCCESS.md` - Complete issue resolution
- `DEPLOYMENT-ISSUES.md` - Troubleshooting guide
- `STORAGE-FIX-SUMMARY.md` - Storage configuration
- `SCRIPTS-README.md` - Script documentation
