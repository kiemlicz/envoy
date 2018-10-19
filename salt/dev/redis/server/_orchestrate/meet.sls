{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set this_host = grains['id'] %}

{% if redis.docker is defined %}
  {% set initiator = grains["redis"]["pods"]|first %}
  {% set initiator_details = salt['mine.get'](tgt="redis:pods:" ~ initiator, fun=initiator, tgt_type="grain") %}
  {% set initiator_envs = initiator_details[this_host]["Config"]["Env"] %}
  {% set initiator_id = initiator_details[this_host]["Id"] %}
  {% set initiator_ip = (salt.filters.find(initiator_envs, "POD_IP=\d+\.\d+\.\d+\.\d+")|first).split("=")[1] %}
  {% set initiator_port = redis.port %}
  {% for minion, pods in salt['mine.get'](tgt="redis:pods:*", fun="redis_pods", tgt_type="grain").items() -%}
    {%- for pod in pods %}
      {%- set pod_details = salt['mine.get'](tgt=minion, fun=pod).values()[0] %}
      {%- set other_ip = (salt.filters.find(pod_details["Config"]["Env"], "POD_IP=\d+\.\d+\.\d+\.\d+")|first).split("=")[1] %}
      {%- set other_port = redis.port %}
      redis_{{ initiator }}_cluster_meet_{{ other_ip }}_{{ other_port }}:
        module.run:
          - docker.run:
            - name: {{ initiator_id }}
            - cmd: redis-cli -h {{ initiator_ip }} -p {{ initiator_port }} CLUSTER MEET {{ other_ip }} {{ other_port }}
    {%- endfor %}
  {%- endfor %}
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
