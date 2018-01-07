{% from "redis/server/single/map.jinja" import redis with context %}
{% from "_macros/dev_tool.macros.jinja" import redis_install with context %}

include:
  - pkgs

{{ redis_install(redis.pkg_name, redis.init, redis.init_location, "os_packages") }}
