redis:
  config: salt://redis.conf
  pidfile_dir: /var/run/redis/
  run_dir: /var/lib/redis/
  init: salt://redis.init
  init_location: /etc/init.d/redis-server
  service: redis-server
  port: 1234
