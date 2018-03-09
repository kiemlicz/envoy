keepalived:
  service1:  &service1
    virtual_router_id: 11
    interface: eth0
    lvs_sync_daemon_inteface: eth1
    advert_int: 1
    authentication:
      auth_type: PASS
      auth_pass: somepass
    virtual_ipaddress:
      - 10.10.253.99 dev eth0
  virtual_servers:
    "192.168.1.20 22":
      delay_loop: 6
      lb_algo: sh
      lb_kind: dr
      protocol: TCP
      quorum: 1
  real_servers:
    "192.168.1.66 22":
      weight: 1
      TCP_CHECK:
        connect_timeout: 3
        connect_port: 22
  minion1:
    vrrp_instances:
      service1:
        <<: *service1
        state: MASTER
        priority: 100
  minion2:
    vrrp_instances:
      service1:
        <<:  *service1
        state: BACKUP
        priority: 50

