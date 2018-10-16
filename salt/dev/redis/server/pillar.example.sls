redis:
  setup_type: cluster # cluster, single
  port: 6379 #for single setup_type
  ip: 127.0.0.1 #for single setup_type
  total_slots: 16384
  config:
    source: salt://redis.conf
    dir: /var/lib/redis
    pid: /var/run/redis/redis-server.pid
    init: salt://redis.init
    init_location: /etc/init.d/redis-server
    service: redis-server
  instances:
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
---
redis:
  instances:
    masters:
    - id: minionid
      #orchestrator must know ip, someone will have to pass this IP
      port: 1234
    - id: minionid
      port: 1234
    slaves:
    - id: minionid
      ofmaster:
        id: minionid
        port: 1234
      port: 1235
    - id: minionid
      ofmaster:
        id: minionid
        port: 1234
      port: 1235