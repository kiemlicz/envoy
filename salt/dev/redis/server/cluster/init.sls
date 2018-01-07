{% from "redis/server/cluster/map.jinja" import redis with context %}
{% from "_macros/dev_tool.macros.jinja" import redis_install with context %}
{% from "_macros/dev_tool.macros.jinja" import redis_configure with context %}

{% set this_host = grains['id'] %}
{% set all_instances = redis.master_bind_list + redis.slave_bind_list %}

{% if this_host in all_instances|map(attribute='host_id')|list %}

include:
  - pkgs

{{ redis_install(redis.pkg_name, redis.init, redis.init_location, "os_packages") }}

{% for bind in all_instances|selectattr("host_id", "equalto", this_host)|list %}

{{ redis_configure(redis.host, redis.port, redis.config, redis.init_location, redis.service) }}

{% endfor %}

{% endif %}
