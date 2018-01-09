{% from "redis/server/single/map.jinja" import redis with context %}
{% from "redis/server/macros.jinja" import redis_install with context %}

include:
  - pkgs

{{ redis_install(redis) }}
