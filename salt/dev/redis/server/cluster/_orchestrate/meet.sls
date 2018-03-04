{% from "redis/server/cluster/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set this_host = grains['id'] %}

{% set master = redis.masters|selectattr("id", "equalto", this_host)|first %}
{% set master_ip = master.ip|default(ip()) %}

redis_master_{{ master_ip }}_{{ master.port }}_cluster_meet:
  cmd.run:
    - names:
{% for other in redis.masters + redis.slaves %}
{% set other_ip = other.ip|default(ip(id=other.id)) %}
      - redis-cli -h {{ master_ip }} -p {{ master.port }} CLUSTER MEET {{ other_ip }} {{ other.port }}
{% endfor %}
