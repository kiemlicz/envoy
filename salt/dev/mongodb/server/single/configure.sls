{% from "mongodb/server/single/map.jinja" import mongodb with context %}
{% from "_common/ip.jinja" import ip with context %}
{% from "_common/util.jinja" import is_docker with context %}


{% set bind = {
  'port': mongodb.port,
  'ip': mongodb.ip|default(ip())
} %}
mongodb_config_{{ bind.ip }}_{{ bind.port }}:
  file_ext.managed:
    - name: /etc/{{ mongodb.config.service }}.conf
    - source: {{ mongodb.config.source }}
    - makedirs: True
    - template: jinja
    - context:
      bind: {{ bind }}
      mongodb: {{ mongodb }}
      discriminator: {{ mongodb.config.service }}
    - require:
      - file_ext: {{ mongodb.config.init_location }}
  service.running:
    - name: {{ mongodb.config.service }}
{% if not is_docker() %}
    - enable: True
{% endif %}
    - require:
      - file: /etc/{{ mongodb.config.service }}.conf
