{% from "redis/server/cluster/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set this_host = grains['id'] %}
{% for master in redis.masters|selectattr("id", "equalto", this_host)|list %}

{% set master_ip = master.ip|default(ip()) %}

redis_master_{{ master_ip }}_{{ master.port }}_assign_slots:
  cmd.run:
    - name: redis-cli -h {{ master_ip }} -p {{ master.port }} CLUSTER ADDSLOTS {{ salt['pillar.get']('redis:slots:' + this_host)|join(" ") }}

{% endfor %}
