{% from "redis/server/single/map.jinja" import redis with context %}
{% from "redis/server/macros.jinja" import redis_configure with context %}

{{ redis_configure(redis) }}
