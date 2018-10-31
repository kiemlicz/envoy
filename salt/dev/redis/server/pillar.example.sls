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
    - name: minionid
      ip: 1.2.3.4
      port: 1234
    - name: minionid_other
      ip: 1.2.3.5
      port: 1234
    - name: some_name_not_minion
      ip: 1.2.3.4
      port: 1236
    slaves:
    - name: minionidslave
      of_master: minionid
      ip: 1.2.3.6
      port: 1235
---
redis:
  instances:
    masters:
    - name: pod1
    - name: pod2
    slaves:
    - name: pod3
      ofmaster: pod1
    - name: pod4
      ofmaster: pod2
