// Add subscriber for IMSI 001011000000001
db = db.getSiblingDB('open5gs');

// Remove existing subscriber if any
db.subscribers.deleteOne({ imsi: "001011000000001" });

// Insert the subscriber matching the UE configuration
db.subscribers.insertOne({
  imsi: "001011000000001",
  subscribed_rau_tau_timer: 12,
  network_access_mode: 0,
  subscriber_status: 0,
  access_restriction_data: 32,
  slice: [
    {
      sst: 1,
      default_indicator: true,
      session: [
        {
          name: "embb.testbed",
          type: 3,  // IPv4
          pcc_rule: [],
          ambr: {
            uplink: { value: 1, unit: 3 },    // 1 Gbps
            downlink: { value: 1, unit: 3 }   // 1 Gbps
          },
          qos: {
            index: 9,
            arp: {
              priority_level: 8,
              pre_emption_capability: 1,
              pre_emption_vulnerability: 1
            }
          }
        }
      ]
    }
  ],
  ambr: {
    uplink: { value: 1, unit: 3 },    // 1 Gbps  
    downlink: { value: 1, unit: 3 }   // 1 Gbps
  },
  security: {
    k: "465B5CE8B199B49FAA5F0A2EE238A6BC",
    opc: "E8ED289DEBA952E4283B54E88E6183CA",
    amf: "8000",
    sqn: NumberLong(0)
  }
});

print("Subscriber 001011000000001 added successfully!");
