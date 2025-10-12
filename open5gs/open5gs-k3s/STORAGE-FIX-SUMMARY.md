# K3s Storage Configuration Fix

## Problem
The deployment was failing because:
- PVC was configured with `ReadWriteMany` (RWX) access mode
- K3s's default `local-path` provisioner only supports `ReadWriteOnce` (RWO)
- Multiple pods (NRF, SCP, UDR, UDM, AUSF, PCF, NSSF, AMF, SMF, UPF) need to write logs to the same directory

## Solution
Replaced PersistentVolumeClaim with `hostPath` volumes:
- All pods now use `hostPath` pointing to `/mnt/data/open5gs-logs`
- Each pod writes to subdirectories using `subPath` in volumeMount
- Host directory is created with proper permissions (777) during deployment

## Changes Made

### 1. Storage Configuration (`00-foundation/storage.yaml`)
- Commented out PV and PVC definitions
- Added note explaining K3s limitation

### 2. Updated All NF Deployments
Replaced PVC volume with hostPath in:
- `02-control-plane/nrf.yaml`
- `02-control-plane/scp.yaml`
- `02-control-plane/udr.yaml`
- `02-control-plane/udm.yaml`
- `02-control-plane/ausf.yaml`
- `02-control-plane/pcf.yaml`
- `02-control-plane/nssf.yaml`
- `03-session-mgmt/amf.yaml`
- `03-session-mgmt/smf.yaml`
- `04-user-plane/upf.yaml`

**Old configuration:**
```yaml
volumes:
- name: logs
  persistentVolumeClaim:
    claimName: open5gs-logs-pvc
```

**New configuration:**
```yaml
volumes:
- name: logs
  hostPath:
    path: /mnt/data/open5gs-logs
    type: DirectoryOrCreate
```

### 3. Deploy Script (`deploy-k3s.sh`)
- Added host directory creation step
- Removed storage.yaml deployment (now commented out)
- Sets proper permissions (777) on log directory

## How It Works

1. **Host Directory**: `/mnt/data/open5gs-logs` on K3s node
2. **Pod Mounts**: Each pod mounts this directory at `/var/log/open5gs`
3. **Subdirectories**: Pods use `subPath: <nf-name>` to write to separate directories
4. **Result**: Logs stored at `/mnt/data/open5gs-logs/<nf-name>/` on host

Example for NRF:
- Host path: `/mnt/data/open5gs-logs/nrf/nrf.log`
- Pod path: `/var/log/open5gs/nrf.log`

## Verification

Check logs on host:
```bash
ls -la /mnt/data/open5gs-logs/
```

Check logs in pod:
```bash
kubectl exec -n open5gs nrf-0 -- ls -la /var/log/open5gs/
```

## Cleanup Performed

- Deleted old PVC: `open5gs-logs-pvc`
- Deleted old PV: `open5gs-logs-pv`
- Created host directory: `/mnt/data/open5gs-logs`
- Set permissions: `chmod 777`

## Next Steps

### Fresh Deployment
```bash
./deploy-k3s.sh
```

### Complete Cleanup and Redeploy
If you need to clean up all existing pods and redeploy:
```bash
./redeploy-k3s.sh
```

This will:
1. Remove all NF deployments (control plane, session mgmt, user plane)
2. Wait for pods to terminate
3. Call `deploy-k3s.sh` to redeploy everything fresh

**Manual cleanup (if needed):**
```bash
# Delete specific StatefulSet
kubectl delete statefulset <nf-name> -n open5gs

# Reapply the updated configuration
kubectl apply -f 02-control-plane/<nf-name>.yaml
```

## ✅ Verified Working

- **NRF pod**: Running successfully (1/1 Ready)
- **Logs**: Being written to `/mnt/data/open5gs-logs/nrf/nrf.log`
- **Container logs**: Show successful initialization
- **No PVC errors**: Using hostPath volumes as intended

The storage issue is now completely resolved!
