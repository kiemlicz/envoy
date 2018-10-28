{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set this_host = grains['id'] %}

{% if redis.docker is defined %}

  {% set pods = salt['kube_ext.app_info']("redis-cluster") %}
  {% for k in pods %}
    {% do pods[k].update({'port': redis.port}) %}
  {% endfor %}

  redis_cluster_meet:
    redis_ext.meet:
      - name: redis_cluster_meet
      - nodes_map: {{ pods }}

{% else %}
  {% set master = redis.masters|selectattr("id", "equalto", this_host)|first %}
  {% set master_ip = master.ip|default(ip()) %}
  redis_master_{{ master_ip }}_{{ master.port }}_cluster_meet:
    cmd.run:
      - names:
    {% for other in redis.masters + redis.slaves %}
      {% set other_ip = other.ip|default(ip(id=other.id)) %}
        - redis-cli -h {{ master_ip }} -p {{ master.port }} CLUSTER MEET {{ other_ip }} {{ other.port }}
    {% endfor %}
{% endif %}
