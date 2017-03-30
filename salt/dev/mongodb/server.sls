{% from "mongodb/map.jinja" import mongodb_repo with context %}
{% from "mongodb/map.jinja" import mongodb_docker with context %}
{% from "mongodb/map.jinja" import setup_type with context %}

{% if setup_type == 'repo' %}
mongodb:
  pkgrepo.managed:
    - names: {{ mongodb_repo.repo_entries }}
    - file: {{ mongodb_repo.file }}
    - keyid: {{ mongodb_repo.keyid }}
    - keyserver: {{ mongodb_repo.keyserver }}
    - require_in:
      - pkg: {{ mongodb_repo.pkg_name }}
  pkg.installed:
    - name: {{ mongodb_repo.pkg_name }}
  service.running:
    - name: {{ mongodb_repo.service_name }}
    - enable: True
    - require:
      - pkg: {{ mongodb_repo.pkg_name }}

{% elif setup_type == 'docker' %}

{% from "docker/map.jinja" import docker with context %}

mongo_in_docker_prerequisites:
  pkg.installed:
    - pkgs: {{ mongodb_docker.prerequisites }}
  pip.installed:
    - pkgs: {{ mongodb_docker.pip_pkgs }}
    - reload_modules: True
    - require_in:
      - dockerng: {{ mongodb_docker.name }}

mongodb:
  dockerng.running:
    - name: {{ mongodb_docker.name }}
    - image: {{ mongodb_docker.image }}
    {% for host in mongodb_docker.bind_addresses %}
    - port_bindings:
      - {{ host }}:{{ mongodb_docker.bind_port }}:{{ mongodb_docker.container_port }}
    {% endfor %}
    - require:
      - service: {{ docker.service_name }}
      - pkg: mongo_in_docker_prerequisites

{% endif %}

# todo add conf/log/db_path file management