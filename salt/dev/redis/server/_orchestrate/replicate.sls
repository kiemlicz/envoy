{% from "redis/server/macros.jinja" import redis_master_id with context %}
{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set this_host = grains['id'] %}

{% if redis.docker is defined %}
  {% for pod_name in grains["redis"]["pods"] if pod_name in salt['pillar.get']("redis:docker:slaves", [])|map(attribute='pod')|list %}
    {% set master_info = salt['pillar.get']("redis:docker:slaves", [])|selectattr("pod", "equalto", pod_name)|first %}
    {% set master_pod_name = master_info["master_pod"] %}
    {% set master_pod_details = salt['mine.get'](tgt="redis:pods:*", fun=master_pod_name, tgt_type="grain").values()[0] %}
    {% set pod_details = salt['mine.get'](tgt=this_host, fun=pod_name) %}
    {% set container_id = pod_details[this_host]["Id"] %}
    {% set instance_ip = (salt.filters.find(pod_details[this_host]["Config"]["Env"], "POD_IP=\d+\.\d+\.\d+\.\d+")|first).split("=")[1] %}
    {% set instance_port = redis.port %}
    {% set master_ip = (salt.filters.find(master_pod_details["Config"]["Env"], "POD_IP=\d+\.\d+\.\d+\.\d+")|first).split("=")[1] %}
    {% set master_port = master_info["master_port"]  %}
    {% set redis_master_id = redis_master_id(master_ip, master_port, container_id) %}
    redis_slave_{{ instance_ip }}_{{ instance_port }}_replicate_master:
      module.run:
        - docker.run:
          - name: {{ container_id }}
          - cmd: redis-cli -h {{ instance_ip }} -p {{ instance_port }} CLUSTER REPLICATE {{ redis_master_id }}
  {% endfor %}
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
