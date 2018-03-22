{% from "mongodb/server/cluster/map.jinja" import mongodb with context %}
{% from "mongodb/server/macros.jinja" import mongodb_configure with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set this_host = grains['id'] %}
{% set all_instances = mongodb.replicas + mongodb.shards %}
{% for bind in all_instances|selectattr("id", "equalto", this_host)|list %}

{% do bind.update({
  "ip": bind.ip|default(ip())
}) %}
{{ mongodb_configure(mongodb, bind, mongodb.config.service + '-' + bind.port|string) }}

{% endfor %}
