#!/bin/bash

# Create directory if needed
for nf in ausf bsf hss mme nrf nssf pcf pcrf scp sgwc sgwu smf udm udr upf; do
    mkdir -p $nf
done

# Update or create YAML files with container network IPs (10.10.0.0/24)

# AMF configuration (already exists, just ensure it's updated)
cat > amf/amf.yaml << 'EOF'
logger:
  file:
    path: /var/log/open5gs/amf.log
    timestamp: true

global:
  max:
    ue: 1024

amf:
  sbi:
    server:
      - address: 10.10.0.5
        port: 7777
    client:
      scp:
        - uri: http://10.10.0.200:7777
  ngap:
    server:
      - address: 0.0.0.0  # Bind to all interfaces for external gNB
        port: 38412
  metrics:
    server:
      - address: 10.10.0.5
        port: 9090
  guami:
    - plmn_id:
        mcc: 001
        mnc: 01
      amf_id:
        region: 2
        set: 1
  tai:
    - plmn_id:
        mcc: 001
        mnc: 01
      tac: 1
  plmn_support:
    - plmn_id:
        mcc: 001
        mnc: 01
      s_nssai:
        - sst: 1
  security:
    integrity_order : [ NIA2, NIA1, NIA0 ]
    ciphering_order : [ NEA0, NEA1, NEA2 ]
  network_name:
    full: Open5GS
    short: Next
  amf_name: open5gs-amf0
  time:
    t3512:
      value: 540
EOF

# AUSF configuration
cat > ausf/ausf.yaml << 'EOF'
logger:
  file:
    path: /var/log/open5gs/ausf.log
    timestamp: true

global:
  max:
    ue: 1024

ausf:
  sbi:
    server:
      - address: 10.10.0.11
        port: 7777
    client:
      scp:
        - uri: http://10.10.0.200:7777
EOF

# BSF configuration
cat > bsf/bsf.yaml << 'EOF'
logger:
  file:
    path: /var/log/open5gs/bsf.log
    timestamp: true

global:
  max:
    ue: 1024

bsf:
  sbi:
    server:
      - address: 10.10.0.15
        port: 7777
    client:
      scp:
        - uri: http://10.10.0.200:7777
EOF

# HSS configuration
cat > hss/hss.yaml << 'EOF'
db_uri: mongodb://mongodb:27017/open5gs
logger:
  file:
    path: /var/log/open5gs/hss.log
    timestamp: true

global:
  max:
    ue: 1024

hss:
  freeDiameter: /etc/freeDiameter/hss.conf
  metrics:
    server:
      - address: 10.10.0.8
        port: 9090
EOF

# MME configuration
cat > mme/mme.yaml << 'EOF'
logger:
  file:
    path: /var/log/open5gs/mme.log
    timestamp: true

global:
  max:
    ue: 1024

mme:
  freeDiameter: /etc/freeDiameter/mme.conf
  s1ap:
    server:
      - address: 10.10.0.2
  gtpc:
    server:
      - address: 10.10.0.2
    client:
      sgwc:
        - address: 10.10.0.3
      smf:
        - address: 10.10.0.4
  metrics:
    server:
      - address: 10.10.0.2
        port: 9090
  gummei:
    - plmn_id:
        mcc: 999
        mnc: 70
      mme_gid: 2
      mme_code: 1
  tai:
    - plmn_id:
        mcc: 999
        mnc: 70
      tac: 1
  security:
    integrity_order : [ EIA2, EIA1, EIA0 ]
    ciphering_order : [ EEA0, EEA1, EEA2 ]
  network_name:
    full: Open5GS
    short: Next
  mme_name: open5gs-mme0
EOF

# NRF configuration
cat > nrf/nrf.yaml << 'EOF'
logger:
  file:
    path: /var/log/open5gs/nrf.log
    timestamp: true

global:
  max:
    ue: 1024

nrf:
  serving:
    - plmn_id:
        mcc: 001
        mnc: 01
  sbi:
    server:
      - address: 10.10.0.10
        port: 7777
EOF

# NSSF configuration
cat > nssf/nssf.yaml << 'EOF'
logger:
  file:
    path: /var/log/open5gs/nssf.log
    timestamp: true

global:
  max:
    ue: 1024

nssf:
  sbi:
    server:
      - address: 10.10.0.14
        port: 7777
    client:
      scp:
        - uri: http://10.10.0.200:7777
      nsi:
        - uri: http://10.10.0.10:7777
          s_nssai:
            sst: 1
EOF

# PCF configuration
cat > pcf/pcf.yaml << 'EOF'
db_uri: mongodb://mongodb:27017/open5gs
logger:
  file:
    path: /var/log/open5gs/pcf.log
    timestamp: true

global:
  max:
    ue: 1024

pcf:
  sbi:
    server:
      - address: 10.10.0.13
        port: 7777
    client:
      scp:
        - uri: http://10.10.0.200:7777
  metrics:
    server:
      - address: 10.10.0.13
        port: 9090
EOF

# PCRF configuration
cat > pcrf/pcrf.yaml << 'EOF'
db_uri: mongodb://mongodb:27017/open5gs
logger:
  file:
    path: /var/log/open5gs/pcrf.log

global:
  max:
    ue: 1024

pcrf:
  freeDiameter: /etc/freeDiameter/pcrf.conf
  metrics:
    server:
      - address: 10.10.0.9
        port: 9090
EOF

# SCP configuration
cat > scp/scp.yaml << 'EOF'
logger:
  file:
    path: /var/log/open5gs/scp.log
    timestamp: true

global:
  max:
    ue: 1024

scp:
  sbi:
    server:
      - address: 10.10.0.200
        port: 7777
    client:
      nrf:
        - uri: http://10.10.0.10:7777
EOF

# SGW-C configuration
cat > sgwc/sgwc.yaml << 'EOF'
logger:
  file:
    path: /var/log/open5gs/sgwc.log
    timestamp: true

global:
  max:
    ue: 1024

sgwc:
  gtpc:
    server:
      - address: 10.10.0.3
  pfcp:
    server:
      - address: 10.10.0.3
    client:
      sgwu:
        - address: 10.10.0.6
EOF

# SGW-U configuration
cat > sgwu/sgwu.yaml << 'EOF'
logger:
  file:
    path: /var/log/open5gs/sgwu.log
    timestamp: true

global:
  max:
    ue: 1024

sgwu:
  pfcp:
    server:
      - address: 10.10.0.6
  gtpu:
    server:
      - address: 10.10.0.6
EOF

# SMF configuration
cat > smf/smf.yaml << 'EOF'
logger:
  file:
    path: /var/log/open5gs/smf.log
    timestamp: true

global:
  max:
    ue: 1024

smf:
  sbi:
    server:
      - address: 10.10.0.4
        port: 7777
    client:
      scp:
        - uri: http://10.10.0.200:7777
  pfcp:
    server:
      - address: 10.10.0.4
    client:
      upf:
        - address: 10.10.0.7
  gtpc:
    server:
      - address: 10.10.0.4
  gtpu:
    server:
      - address: 10.10.0.4
  metrics:
    server:
      - address: 10.10.0.4
        port: 9090
  session:
    - subnet: 10.45.0.0/16
      gateway: 10.45.0.1
    - subnet: 2001:db8:cafe::/48
      gateway: 2001:db8:cafe::1
  dns:
    - 8.8.8.8
    - 8.8.4.4
    - 2001:4860:4860::8888
    - 2001:4860:4860::8844
  mtu: 1400
  freeDiameter: /etc/freeDiameter/smf.conf
EOF

# UDM configuration
cat > udm/udm.yaml << 'EOF'
logger:
  file:
    path: /var/log/open5gs/udm.log
    timestamp: true

global:
  max:
    ue: 1024

udm:
  sbi:
    server:
      - address: 10.10.0.12
        port: 7777
    client:
      scp:
        - uri: http://10.10.0.200:7777
EOF

# UDR configuration
cat > udr/udr.yaml << 'EOF'
db_uri: mongodb://mongodb:27017/open5gs
logger:
  file:
    path: /var/log/open5gs/udr.log
    timestamp: true

global:
  max:
    ue: 1024

udr:
  sbi:
    server:
      - address: 10.10.0.20
        port: 7777
    client:
      scp:
        - uri: http://10.10.0.200:7777
EOF

# UPF configuration
cat > upf/upf.yaml << 'EOF'
logger:
  file:
    path: /var/log/open5gs/upf.log
    timestamp: true

global:
  max:
    ue: 1024

upf:
  pfcp:
    server:
      - address: 10.10.0.7
  gtpu:
    server:
      - address: 0.0.0.0  # Bind to all interfaces for external gNB
        port: 2152      # Standard port, can use 2153 as alternative
  session:
    - subnet: 10.45.0.0/16
      gateway: 10.45.0.1
    - subnet: 2001:db8:cafe::/48
      gateway: 2001:db8:cafe::1
  metrics:
    server:
      - address: 10.10.0.7
        port: 9090
EOF

echo "All YAML configuration files have been updated for container network!"