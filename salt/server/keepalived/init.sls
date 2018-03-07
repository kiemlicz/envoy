{% from "keepalived/map.jinja" import keepalived with context %}


include:
  - pkgs

#disable arp

keepalived:
  pkg.latest:
    - name: {{ keepalived.pkg_name }}
    - require:
      - pkg: os_packages

{% for config in keepalived.configs.values() %}
{% set instances = keepalived[grains["id"]] %}
{# fill interfaces #}

keepalived_config_{{ config.location }}:
  file_ext.managed:
    - name: {{ config.location }}
    - source: {{ config.source }}
    - makedirs: True
    - template: jinja
    - context:
      instances: {{ instances }}

    - require:
      - pkg: {{ keepalived.pkg_name }}

{% endfor %}
