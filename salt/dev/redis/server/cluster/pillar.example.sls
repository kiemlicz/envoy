redis:
  total_slots: 16384
  masters:
    - id: minionid
      ip: 1.2.3.4
      port: 1234
    - id: minionid_other
      ip: 1.2.3.5
      port: 1234
  slaves:
    - id: minionid
      of_master:
        id: minionid
        ip: 1.2.3.4
        port: 1234
      ip: 1.2.3.6
      port: 1235

