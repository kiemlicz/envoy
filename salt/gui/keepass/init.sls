{% from "keepass/map.jinja" import keepass with context %}

include:
  - pkgs


keepass:
  pkg.installed:
{% if keepass.url is defined %}
    - sources:
      - {{ keepass.pkg_name }}: {{ keepass.url }}
{% else %}
    - name: {{ keepass.pkg_name }}
{% endif %}
    - require:
      - pkg: os_packages
