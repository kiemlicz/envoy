{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set this_host = grains['id'] %}

{% if redis.docker is defined %}
  {% for pod_name in grains["redis"]["pods"] if pod_name in salt['pillar.get']("redis:docker:masters", [])|map(attribute='pod')|list %}
    {% set pod_details = salt['mine.get'](tgt=this_host, fun=pod_name) %}
    {% set container_id = pod_details[this_host]["Id"] %}
    {% set container_envs = pod_details[this_host]["Config"]["Env"] %}
    {% set instance_ip = (salt.filters.find(container_envs, "POD_IP=\d+\.\d+\.\d+\.\d+")|first).split("=")[1] %}
    {% set instance_port = redis.port %}
    redis_master_{{ instance_ip }}_{{ instance_port }}_assign_slots:
      module.run:
        - docker.run:
          - name: {{ container_id }}
          - cmd: redis-cli -h {{ instance_ip }} -p {{ instance_port }} CLUSTER ADDSLOTS {{ salt['pillar.get']('redis:slots:' ~ pod_name)|join(" ") }}
  {% endfor %}
{% else %}
  {% for master in redis.masters|selectattr("id", "equalto", this_host)|list %}

  {% set master_ip = master.ip|default(ip()) %}

  redis_master_{{ master_ip }}_{{ master.port }}_assign_slots:
    cmd.run:
      - name: redis-cli -h {{ master_ip }} -p {{ master.port }} CLUSTER ADDSLOTS {{ salt['pillar.get']('redis:slots:' ~ this_host)|join(" ") }}

  {% endfor %}
{% endif %}
