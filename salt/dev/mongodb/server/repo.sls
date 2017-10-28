{% from "mongodb/server/repo.map.jinja" import mongodb with context %}

mongodb:
  pkgrepo.managed:
    - names: {{ mongodb.repo_entries }}
    - file: {{ mongodb.file }}
    - keyid: {{ mongodb.keyid }}
    - keyserver: {{ mongodb.keyserver }}
    - require_in:
      - pkg: {{ mongodb.pkg_name }}
  pkg.latest:
    - name: {{ mongodb.pkg_name }}
    - require:
      - pkg: os_packages
  service.running:
    - name: {{ mongodb.service_name }}
    - enable: True
    - require:
      - pkg: {{ mongodb.pkg_name }}
