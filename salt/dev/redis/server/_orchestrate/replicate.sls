{% from "redis/server/macros.jinja" import redis_master_id with context %}
{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set this_host = grains['id'] %}

{% if redis.docker is defined %}
  {%- set slave_names_list = salt['pillar.get']("redis:docker:slaves", [])|map(attribute='pod')|list %}
  {%- for minion, pods_map in salt['mine.get'](tgt=this_host, fun="redis_pods").items() %}
    {%- for pod_id, details in pods_map.items() if details['Labels']['io.kubernetes.pod.name'] in slave_names_list %}
      {%- set slave_pod_name = details['Labels']['io.kubernetes.pod.name'] %}
      {%- set master_slave_binding = salt['pillar.get']("redis:docker:slaves", [])|selectattr("pod", "equalto", slave_pod_name)|first %}
      {%- set master_pod_name = master_slave_binding["master_pod"] %}
      {%- set master_pod_details = salt.kubehelp.pod_info(master_pod_name, this_host) %}
      {%- set slave_pod_details = salt.kubehelp.pod_info(slave_pod_name, this_host) %}
      {%- set slave_container_id = slave_pod_details['id'] %}
      {%- set slave_ip = slave_pod_details['ips']|first %}
      {%- set slave_port = redis.port %}
      {%- set master_ip = master_pod_details['ips']|first %}
      {%- set master_port = master_slave_binding["master_port"]  %}
      {%- set redis_master_id = redis_master_id(master_ip, master_port, slave_container_id) %}
      redis_slave_{{ slave_ip }}_{{ slave_port }}_replicate_master:
        module.run:
          - docker.run:
            - name: {{ slave_container_id }}
            - cmd: redis-cli -h {{ slave_ip }} -p {{ slave_port }} CLUSTER REPLICATE {{ redis_master_id }}
    {% endfor %}
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
