{% from "docker/map.jinja" import docker with context %}

docker:
{% if grains['os'] != 'Windows' %}
  pkgrepo.managed:
    - names: {{ docker.repo_entries }}
    - file: {{ docker.file }}
    - keyid: {{ docker.keyid }}
    - keyserver: {{ docker.keyserver }}
    - refresh_db: true
    - require_in:
      - pkg: {{ docker.pkg_name }}
{% endif %}
  pkg.latest:
    - name: {{ docker.pkg_name }}
    - refresh: True
  service.running:
    - name: {{ docker.service_name }}
    - enable: True
    - require:
      - pkg: {{ docker.pkg_name }}
