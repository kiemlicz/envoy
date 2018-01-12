{% from "mongodb/server/single/map.jinja" import mongodb with context %}

mongodb:
{% if grains['os'] != 'Windows' %}
  pkgrepo.managed:
    - names: {{ mongodb.repo_entries }}
    - file: {{ mongodb.file }}
    - keyid: {{ mongodb.keyid }}
    - keyserver: {{ mongodb.keyserver }}
    - require:
      - pkg: os_packages
    - require_in:
      - pkg: {{ mongodb.pkg_name }}
{% endif %}
  pkg.latest:
    - name: {{ mongodb.pkg_name }}
    - require:
      - pkg: os_packages
  service.running:
    - name: {{ mongodb.service }}
{% if salt['grains.get']("virtual_subtype") != "Docker" %}
    - enable: True
{% endif %}
    - require:
      - pkg: {{ mongodb.pkg_name }}
