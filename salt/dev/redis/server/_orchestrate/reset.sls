{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set this_host = grains['id'] %}

{% if redis.docker is defined %}
  {% for instance_number in range(redis.size) %}
    {% set fun = redis.docker.app ~ salt['pillar.get']("kube:delim") ~ instance_number|string %}
    {% set docker_inspect = salt['mine.get'](tgt=this_host, fun=fun) %}
    {% if this_host in docker_inspect %}
      {% set container_id = docker_inspect[this_host]["Id"] %}
      {% set docker_envs = docker_inspect[this_host]["Config"]["Env"] %}
      {% set instance_ip = (salt.filters.find(docker_envs, "POD_IP=\d+\.\d+\.\d+\.\d+")|first).split("=")[1] %}
      {% set instance_port = redis.port %}

      redis_{{ container_id }}_cluster_reset:
        module.run:
          - name: docker.run
          - m_name: {{ container_id }}
          - cmd: 'redis-cli -h {{ instance_ip }} -p {{ instance_port }} cluster reset'
    {% endif %}
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
