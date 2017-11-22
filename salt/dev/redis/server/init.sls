{% from "redis/map.jinja" import setup_type with context %}

{% if setup_type == 'single' %}

include:
  - redis.server.single

{% elif setup_type == 'cluster' %}

{% from "redis/server/cluster.map.jinja" import redis with context %}

{% if grains['host'] in redis.master_bind_list|map(attribute='hostname')|list %}
include:
  - redis.server.cluster
{% endif %}

{% endif %}
