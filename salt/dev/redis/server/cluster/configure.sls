{% from "redis/server/cluster/map.jinja" import redis with context %}
{% from "redis/server/macros.jinja" import redis_configure with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set this_host = grains['id'] %}
{% set all_instances = redis.masters + redis.slaves %}
{% for bind in all_instances|selectattr("id", "equalto", this_host)|list %}

{% do bind.update({
  "ip": bind.ip|default(ip())
}) %}
{{ redis_configure(redis, bind, redis.service + '-' + bind.port|string) }}

{% endfor %}
