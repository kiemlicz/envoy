{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set this_host = grains['id'] %}

{% if redis.docker is defined %}
  {% for minion, pods_map in salt['mine.get'](tgt=this_host, fun="redis_pods").items() %}
    {%- for pod_id, details in pods_map.items() %}
      {%- set pod_details = salt.kubehelp.pod_info(details['Labels']['io.kubernetes.pod.name'], minion)  %}
      {%- set instance_ip = pod_details['ips']|first %}
      {%- set instance_id = pod_details['id'] %}
      {%- set instance_port = redis.port %}
      redis_{{ instance_id }}_cluster_reset:
        module.run:
          - docker.run:
            - name: {{ instance_id }}
            - cmd: redis-cli -h {{ instance_ip }} -p {{ instance_port }} CLUSTER RESET
    {% endfor %}
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
