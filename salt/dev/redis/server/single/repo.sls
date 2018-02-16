{% from "redis/server/single/map.jinja" import redis with context %}
{% from "redis/server/macros.jinja" import redis_install with context %}
{% from "redis/server/macros.jinja" import redis_configure with context %}

{% set bind = {
  'host': redis.host,
  'port': redis.port
} %}

include:
  - pkgs

{{ redis_install(redis) }}
{{ redis_configure(redis, bind) }}
