{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set this_host = grains['id'] %}

{% if redis.docker is defined %}
  {% set pods = salt['kube_ext.app_info']("redis-cluster") %}
    {% for k in pods %}
      {% do pods[k].update({'port': redis.port}) %}
    {% endfor %}

  redis_cluster_reset:
    redis_ext.reset:
      - name: redis_cluster_reset
      - nodes_map: {{ pods }}

{% else %}
  {% set all_instances = redis.masters + redis.slaves %}
  {% for instance in all_instances|selectattr("id", "equalto", this_host)|list %}
  {% set instance_ip = instance.ip|default(ip()) %}
  redis_{{ instance_ip }}_{{ instance.port }}_cluster_reset:
    cmd.run:
      - name: redis-cli -h {{ instance_ip }} -p {{ instance.port }} CLUSTER RESET
  {% endfor %}
{% endif %}
