{% from "redis/server/macros.jinja" import redis_master_id with context %}
{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set this_host = grains['id'] %}

{% if redis.docker is defined %}
  {% set slaves_map = {} %}
  {% for slave in salt['pillar.get']("redis:docker:slaves", []) %}
    {% do slaves_map.update({ slave['pod']: {
          'master_name': slave.of_master.pod,
          'master_port': slave.of_master.port
    }}) %}
  {% endfor %}
  
  {% set nodes_map = salt['kube_ext.app_info']("redis-cluster") %}
  {% for k in nodes_map %}
    {% do nodes_map[k].update({'port': redis.port}) %}
  {% endfor %}

{% else %}
  {% set nodes_map = {} %}
  {% set slaves_map = {} %}

  {% for instance in redis.masters + redis.slaves %}
    {% do nodes_map.update({ instance['id']: {
        'ips': [ instance.ip|default(ip(id=instance.id)) ],
        'port': instance.port,
        'minion': instance.id,
      }
    }) %}
  {% endfor %}

  {% for slave in redis.slaves %}
    {% do slaves_map.update({ slave['id']: {
        'ips': [ slave.ip|default(ip(id=slave.id)) ],
        'port': slave.port,
        'minion': slave.id,
        'master_name': slave.of_master.id,
        'master_port': slave.of_master.port,
      }
    }) %}
  {% endfor %}
  {# fixme standarize the pillar for master-slave orchestration #}
{% endif %}

redis_cluster_replicate:
  redis_ext.replicate:
    - name: redis_cluster_replicate
    - nodes_map: {{ nodes_map }}
    - slaves_map: {{ slaves_map }}
