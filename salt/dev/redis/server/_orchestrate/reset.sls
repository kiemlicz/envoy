{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set this_host = grains['id'] %}

{% if redis.docker is defined %}
  {% for pod_name in grains["redis"]["pods"] %}
    {% set pod_details = salt['mine.get'](tgt=this_host, fun=pod_name) %}
    {% set container_id = pod_details[this_host]["Id"] %}
    {% set container_envs = pod_details[this_host]["Config"]["Env"] %}
    {% set instance_ip = (salt.filters.find(container_envs, "POD_IP=\d+\.\d+\.\d+\.\d+")|first).split("=")[1] %}
    {% set instance_port = redis.port %}
    redis_{{ container_id }}_cluster_reset:
      module.run:
        - docker.run:
          - name: {{ container_id }}
          - cmd: redis-cli -h {{ instance_ip }} -p {{ instance_port }} CLUSTER RESET
  {% endfor %}
{% else %}
  {% set all_instances = redis.masters + redis.slaves %}
  {% for instance in all_instances|selectattr("id", "equalto", this_host)|list %}
  {% set instance_ip = instance.ip|default(ip()) %}
  redis_{{ instance_ip }}_{{ instance.port }}_cluster_reset:
    cmd.run:
      - name: redis-cli -h {{ instance_ip }} -p {{ instance.port }} CLUSTER RESET
  {% endfor %}
{% endif %}
