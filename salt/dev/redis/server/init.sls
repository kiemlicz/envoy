{% from "redis/map.jinja" import setup_type with context %}

{% if setup_type == 'single' %}

include:
  - redis.server.single

{% elif setup_type == 'cluster' %}

include:
  - redis.server.cluster

{% endif %}
