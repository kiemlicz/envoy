minions:
  - minion1.local
  - minion2.local
  - minion3.local

redis:
  setup_type: cluster
  masters:
    - id: minion1.local
      port: 6379
      ip: 1.2.3.4
    - id: minion2.local
      port: 6379
      ip: 1.2.3.5
    - id: minion3.local
      port: 6379
      ip: 1.2.3.6
  slaves:
    - id: minion1.local
      master_id: minion2.local
      master_port: 6379
      port: 6380
    - id: minion2.local
      master_id: minion3.local
      master_port: 6379
      port: 6380
    - id: minion3.local
      master_id: minion1.local
      master_port: 6379
      port: 6380

mongodb:
  setup_type: cluster
  install_type: docker
  shards: []
  replicas:
    - id: minion1.local
      master: "True"
      replica_name: "testing"
      port: 28018
    - id: minion1.local
      replica_name: "testing"
      port: 28019
    - id: minion2.local
      replica_name: "testing"
      port: 28018
    - id: minion3.local
      replica_name: "testing"
      port: 28018
    - id: minion4.local
      ip: 1.2.3.9
      replica_name: "testing"
      port: 28018
