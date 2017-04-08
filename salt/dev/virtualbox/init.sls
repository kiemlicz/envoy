{% from "virtualbox/map.jinja" import virtualbox with context %}

include:
  - pkgs

virtualbox:
  pkgrepo.managed:
    - names: {{ virtualbox.repo_entries }}
    - file: {{ virtualbox.file }}
    - key_url: {{ virtualbox.key_url }}
  pkg.installed:
    - name: {{ virtualbox.pkg_name }}
    - require:
      - sls: pkgs
