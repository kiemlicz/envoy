{% from "redis/server/map.jinja" import redis with context %}
{% from "redis/server/macros.jinja" import redis_configure with context %}
{% from "_common/ip.jinja" import ip with context %}


redis_init_script:
  file_ext.managed:
    - name: {{ redis.config.init_location }}
    - source: {{ redis.config.init }}
    - mode: {{ redis.config.mode }}
    - template: jinja
    - context:
      redis: {{ redis|json_decode_dict }}
    - require:
      - pkg: {{ redis.pkg_name }}

{% set this_host = grains['id'] %}
{% set all_instances = redis.masters + redis.slaves %}
{% for bind in all_instances|selectattr("id", "equalto", this_host)|list %}

{% do bind.update({
  "ip": bind.ip|default(ip())
}) %}

{% if salt['grains.get']("init") == 'systemd' %}

{% set instance_number = bind.port|string %}
{% set service = redis.config.service ~ '@' ~ bind.port|string %}
{{ redis_configure(redis, bind, instance_number, service) }}

{% else %}

{% set instance_number = bind.port|string %}
{% set service = redis.config.service ~ '-' ~ instance_number %}
{{ redis_configure(redis, bind, instance_number, service) }}

{% endif%}

{% endfor %}
