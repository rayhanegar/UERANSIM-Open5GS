# Deployment Issues and Fixes

## Issues Found and Fixed

### 1. AMF Service NodePort Out of Range ✅ FIXED
**Error:** `Invalid value: 38412: provided port is not in the valid range. The range of valid ports is 30000-32767`

**Fix:** Changed AMF service nodePort from 38412 to 30412
- File: `03-session-mgmt/amf.yaml`
- Line: nodePort value changed

**Note:** This means UERANSIM gNB needs to connect to port **30412** instead of 38412

### 2. UDM Configuration Error ✅ FIXED
**Error:** `No udm.sbi.address: in '/etc/open5gs/udm.yaml'`

**Fix:** Changed section name from `udr:` to `udm:` in ConfigMap
- File: `01-configmaps/udm-config.yaml`
- The configuration section was incorrectly labeled as `udr` instead of `udm`

**Status:** UDM is now running successfully

### 3. MongoDB Authentication Issues ⚠️ NEEDS VERIFICATION

**Error:** `Authentication failed: Authentication failed.`

**Affected NFs:** PCF, UDR

**Current Configuration:**
- MongoDB IP: `192.168.50.200`
- Connection string: `mongodb://admin:1423@mongodb:27017/open5gs?authSource=admin`
- Credentials: admin / 1423

**Fixes Applied:**
- Updated `pcf-config.yaml` with authentication credentials
- Updated `udr-config.yaml` with authentication credentials

**Status:** Still failing - needs verification of:
1. Is MongoDB actually running at `192.168.50.200:27017`?
2. Are the credentials `admin:1423` correct?
3. Does the MongoDB have the `open5gs` database created?
4. Is the authentication source `admin` correct?

## Current Pod Status

```
NAME     READY   STATUS             RESTARTS      AGE
amf-0    0/1     CrashLoopBackOff   ...          
ausf-0   1/1     Running            0             ✅
nrf-0    1/1     Running            0             ✅
nssf-0   1/1     Running            0             ✅
pcf-0    0/1     CrashLoopBackOff   ...          ❌ (MongoDB auth)
scp-0    1/1     Running            0             ✅
udm-0    1/1     Running            0             ✅
udr-0    0/1     CrashLoopBackOff   ...          ❌ (MongoDB auth)
```

## Next Steps to Resolve MongoDB Issues

### Option 1: Verify Existing MongoDB
```bash
# Test connection from your machine
mongo mongodb://admin:1423@192.168.50.200:27017/open5gs?authSource=admin --eval "db.stats()"

# Or using mongosh
mongosh "mongodb://admin:1423@192.168.50.200:27017/open5gs?authSource=admin" --eval "db.stats()"
```

### Option 2: Check MongoDB Logs/Status
```bash
# If MongoDB is running as systemd service
sudo systemctl status mongod
sudo journalctl -u mongod -n 50

# Check MongoDB logs
sudo tail -f /var/log/mongodb/mongod.log
```

### Option 3: Update MongoDB Credentials
If the credentials are different, update these files:
1. `01-configmaps/pcf-config.yaml` - line with `db_uri:`
2. `01-configmaps/udr-config.yaml` - line with `db_uri:`
3. `02-control-plane/pcf.yaml` - env variable `DB_URI`
4. `02-control-plane/udr.yaml` - env variable `DB_URI`

Then apply and restart:
```bash
kubectl apply -f 01-configmaps/pcf-config.yaml
kubectl apply -f 01-configmaps/udr-config.yaml
kubectl delete pod pcf-0 udr-0 -n open5gs
```

### Option 4: Deploy MongoDB in K3s (Alternative)
If you want to run MongoDB inside K3s instead:
1. Uncomment MongoDB deployment in `docker-compose.yml`
2. Create MongoDB deployment manifests for K3s
3. Update connection string to use internal service name

## AMF Port Change Impact

**Important:** The NGAP port change affects UERANSIM gNB configuration!

Update your UERANSIM gNB config file:
```yaml
# In your gNB configuration
amfConfigs:
  - address: <node-ip>
    port: 30412  # Changed from 38412
```

Where `<node-ip>` is your K3s node's IP address.

## Files Modified

1. `03-session-mgmt/amf.yaml` - Fixed NodePort
2. `01-configmaps/udm-config.yaml` - Fixed section name
3. `01-configmaps/pcf-config.yaml` - Added MongoDB auth
4. `01-configmaps/udr-config.yaml` - Added MongoDB auth
