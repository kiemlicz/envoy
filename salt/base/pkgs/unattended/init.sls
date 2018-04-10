{% from "pkgs/unattended/map.jinja" import unattended with context %}


include:
  - pkgs


unattended_upgrades:
  pkg.latest:
    - name: unattended_upgrades_pkgs
    - pkgs: {{ unattended.required_pkgs }}
    - require:
      - pkg: os_packages

{% for config in unattended.configs %}
unattended_upgrades_{{ config.location }}:
  file.managed:
    - name: {{ config.location }}
    - source: {{ config.source }}
    - template: jinja
    - context:
      settings: {{ config.settings }}
    - require:
      - pkg: unattended_upgrades_pkgs
    - onchanges_in:
      - cmd: unattended_upgrades_reload
{% endfor%}

unattended_upgrades_reload:
  cmd.run:
    - name: "apt-get update"
