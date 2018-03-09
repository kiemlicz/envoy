{% from "docker/map.jinja" import docker with context %}

include:
  - mounts
  - pkgs

docker:
{% if grains['os'] != 'Windows' %}
  pkgrepo.managed:
    - names: {{ docker.repo_entries }}
    - file: {{ docker.file }}
    - key_url: {{ docker.key_url }}
    - refresh_db: true
    - require:
      - sls: pkgs
    - require_in:
      - pkg: {{ docker.pkg_name }}
{% endif %}
{% if salt['grains.get']("virtual_subtype") == 'Docker' %}
# this is workaround for docker-in-docker: "Error response from daemon: error creating aufs mount ... invalid argument"
  file.managed:
    - name: {{ docker.config }}
    - source: salt://docker/daemon.json
    - makedirs: True
    - template: jinja
    - context:
      storage_driver: vfs
{% endif %}
  pkg.latest:
    - name: {{ docker.pkg_name }}
    - refresh: True
    - require:
      - sls: mounts
      - sls: pkgs
  service.running:
    - name: {{ docker.service_name }}
    - enable: True
    - require:
      - pkg: {{ docker.pkg_name }}
