{% from "docker/map.jinja" import docker with context %}
{% from "_common/util.jinja" import is_docker with context %}

include:
  - mounts
  - pkgs

docker:
{% if docker.repo_entries or docker.repo_id is defined %}
  pkgrepo.managed:
{% if docker.repo_entries is defined %}
    - names: {{ docker.repo_entries }}
    - file: {{ docker.file }}
    - key_url: {{ docker.key_url }}
    - refresh_db: true
{% else %}
    - name: {{ docker.repo_id }}
    - baseurl: {{ docker.baseurl }}
    - humanname: {{ docker.repo_id }}
    - gpgcheck: 1
    - gpgkey: {{ docker.gpgkey }}
{% endif %}
    - require:
      - sls: pkgs
    - require_in:
      - pkg: {{ docker.pkg_name }}
{% endif %}
{% if is_docker() %}
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
