include:
  - os
  - redis.server.install
{% if redis.masters|length == 1 %}
  - redis.server.configure_single
{% elif redis.masters|length + redis.slaves|length > 1 %}
  - redis.server.configure_cluster
{% endif %}

