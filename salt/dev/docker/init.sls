{% from "docker/map.jinja" import docker with context %}
{% from "_common/util.jinja" import is_docker with context %}
{% from "_common/repo.jinja" import repository with context %}


include:
  - os


{% set docker_repo_id = "docker_repository" %}
{{ repository(docker_repo_id, docker, enabled=(docker.names is defined or docker.repo_id is defined),
   require=[{'sls': "os"}], require_in=[{'pkg': docker.pkg_name}]) }}
docker:
{% if is_docker()|to_bool %}
# this is workaround for docker-in-docker: "Error response from daemon: error creating aufs mount ... invalid argument"
  file.managed:
    - name: {{ docker.config }}
    - source: salt://docker/daemon.json
    - makedirs: True
    - template: jinja
    - context:
      storage_driver: vfs
    - require_in:
      - pkg: {{ docker.pkg_name }}
{% endif %}
  pkg.latest:
    - name: {{ docker.pkg_name }}
    - refresh: True
    - require:
      - sls: os
  service.running:
    - name: {{ docker.service_name }}
    - enable: True
    - require:
      - pkg: {{ docker.pkg_name }}
