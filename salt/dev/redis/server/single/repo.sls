{% from "redis/server/single/map.jinja" import redis with context %}
{% from "redis/server/macros.jinja" import redis_install with context %}
{% from "redis/server/macros.jinja" import redis_configure with context %}
{% from "_common/ip.jinja" import ip with context %}

{% set bind = {
  'port': redis.port,
  'ip': redis.ip|default(ip())
} %}

include:
  - pkgs

{{ redis_install(redis) }}
{{ redis_configure(redis, bind) }}
