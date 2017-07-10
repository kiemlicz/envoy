{% from "virtualbox/map.jinja" import virtualbox with context %}

include:
  - pkgs

virtualbox:
{% if grains['os'] != 'Windows' %}
  pkgrepo.managed:
    - names: {{ virtualbox.repo_entries }}
    - file: {{ virtualbox.file }}
    - key_url: {{ virtualbox.key_url }}
    - require:
      - sls: pkgs
    - require_in:
      - pkg: {{ virtualbox.pkg_name }}
{% endif %}
  pkg.installed:
    - name: {{ virtualbox.pkg_name }}
    - require:
      - sls: pkgs
