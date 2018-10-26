{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set this_host = grains['id'] %}

{% if redis.docker is defined %}
  {% set initiator_pod = salt['mine.get'](tgt=this_host, fun="redis_pods")[this_host].values()|first %}
  {% set initiator = initiator_pod['Labels']['io.kubernetes.pod.name'] %}
  {% set initiator_info = salt.kubehelp.pod_info(initiator, this_host) %}
  {% set initiator_id = initiator_info['id'] %}
  {% set initiator_ip = initiator_info['ips']|first %}
  {% set initiator_port = redis.port %}
  {%- for minion, pods_map in salt['mine.get'](tgt="*", fun="redis_pods").items() %}
    {%- for pod_id, details in pods_map.items() %}
      {%- set other_pod = salt.kubehelp.pod_info(details['Labels']['io.kubernetes.pod.name'], minion)  %}
      {%- set other_ip = other_pod['ips']|first %}
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
