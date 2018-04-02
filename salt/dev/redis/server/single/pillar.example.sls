redis:
  config:
    source: salt://redis.conf
    db_path: /var/run/redis/
    pid_path: /var/lib/redis/
    init: salt://redis.init
    init_location: /etc/init.d/redis-server
    service: redis-server
  port: 1234
