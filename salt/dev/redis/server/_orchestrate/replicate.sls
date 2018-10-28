{% from "redis/server/macros.jinja" import redis_master_id with context %}
{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set this_host = grains['id'] %}

{% if redis.docker is defined %}
  {% set slaves_map = {} %}
  {% for slave in salt['pillar.get']("redis:docker:slaves", []) %}
    {% do slaves_map.update({ slave['pod']: {
          'master_name': slave['master_pod'],
          'master_port': slave['master_port']
    }}) %}
  {% endfor %}
  
  {% set pods = salt['kube_ext.app_info']("redis-cluster") %}
  {% for k in pods %}
    {% do pods[k].update({'port': redis.port}) %}
  {% endfor %}

  redis_cluster_replicate:
    redis_ext.replicate:
      - name: redis_cluster_replicate
      - nodes_map: {{ pods }}
      - slaves_map: {{ slaves_map }}

{% else %}
  {% for slave in redis.slaves|selectattr("id", "equalto", this_host)|list %}
    {% set slave_ip = slave.ip|default(ip()) %}
    {% set master_ip = slave.of_master.ip|default(ip(id=slave.of_master.id)) %}
    {% set redis_master_id = redis_master_id(master_ip, slave.of_master.port) %}
    redis_slave_{{ slave_ip }}_{{ slave.port }}_replicate_master:
      cmd.run:
        - name: redis-cli -h {{ slave_ip }} -p {{ slave.port }} CLUSTER REPLICATE {{ redis_master_id }}
  {% endfor %}
{% endif %}
