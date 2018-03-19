{% from "redis/server/cluster/map.jinja" import redis with context %}


{% set this_host = grains['id'] %}
{% set all_instances = redis.masters + redis.slaves %}

{% if this_host in all_instances|map(attribute='id')|list %}

include:
  - pkgs
  - redis.server.single.install
  - redis.server.cluster.configure


{% endif %}
