// Fix subscriber for IMSI 001011000000001 with correct format
db = db.getSiblingDB('open5gs');

// Remove existing subscriber
db.subscribers.deleteOne({ imsi: "001011000000001" });

// Insert subscriber with exact format matching working subscribers
db.subscribers.insertOne({
  imsi: "001011000000001",
  ambr: {
    downlink: { value: 1, unit: 3 },
    uplink: { value: 1, unit: 3 }
  },
  schema_version: 1,
  msisdn: [],
  imeisv: "4370816125816151",
  mme_host: [],
  mme_realm: [],
  purge_flag: [],
  access_restriction_data: 32,
  subscriber_status: 0,
  operator_determined_barring: 0,
  network_access_mode: 0,
  subscribed_rau_tau_timer: 12,
  security: {
    k: "465B5CE8 B199B49F AA5F0A2E E238A6BC",
    amf: "8000",
    op: null,
    opc: "E8ED289D EBA952E4 283B54E8 8E6183CA",
    sqn: NumberLong(0)
  },
  slice: [
    {
      sst: 1,
      default_indicator: true,
      session: [
        {
          name: "embb.testbed",
          type: 3,
          pcc_rule: [],
          ambr: {
            uplink: { value: 1, unit: 3 },
            downlink: { value: 1, unit: 3 }
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
  __v: 0
});

print("Subscriber 001011000000001 fixed with correct format!");
