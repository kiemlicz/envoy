{% from "keepass/map.jinja" import keepass with context %}
{% from "_common/util.jinja" import retry with context %}


include:
  - pkgs


keepass:
  pkg.installed:
{% if keepass.url is defined %}
    - sources:
      - {{ keepass.pkg_name }}: {{ keepass.url }}
{{ retry(attempts=2)| indent(4) }}
{% else %}
    - name: {{ keepass.pkg_name }}
{% endif %}
    - require:
      - pkg: os_packages
