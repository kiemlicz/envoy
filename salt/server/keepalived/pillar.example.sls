keepalived:
  minion1:
    vrrp_instances:
      service1:
        state: MASTER
        priority: 100
        virtual_router_id: 11
        interface: eth0
        lvs_sync_daemon_inteface: eth1
        advert_int: 1
        authentication:
            auth_type: PASS
            auth_pass: somepass
        virtual_ipaddress:
          - 1.2.3.4
  minion2:
    vrrp_instances:
      service1:
        state: BACKUP
        priority: 100
        virtual_router_id: 11
        interface: eth0
        lvs_sync_daemon_inteface: eth1
        advert_int: 1
        authentication:
            auth_type: PASS
            auth_pass: somepass
        virtual_ipaddress:
          - 1.2.3.4

