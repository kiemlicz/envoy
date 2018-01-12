{% from "redis/server/single/map.jinja" import redis with context %}
{% from "redis/server/macros.jinja" import redis_configure with context %}

{% set bind = {
  'host': redis.host,
  'port': redis.port
} %}

{{ redis_configure(redis, bind, False) }}
