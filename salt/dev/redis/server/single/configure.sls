{% from "redis/server/single/map.jinja" import redis with context %}
{% from "_macros/dev_tool.macros.jinja" import redis_configure with context %}

{{ redis_configure(redis.host, redis.port|string, redis.config, redis.init_location, redis.service) }}
