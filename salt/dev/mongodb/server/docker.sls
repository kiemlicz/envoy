{% from "mongodb/server/docker.map.jinja" import mongodb with context %}
{% from "docker/map.jinja" import docker with context %}

mongo_in_docker_prerequisites:
  pkg.latest:
    - name: mongo_os_packages_requisites
    - pkgs: {{ mongodb.prerequisites }}
    - require:
      - pkg: os_packages
  pip.installed:
    - pkgs: {{ mongodb.pip_packages }}
    - reload_modules: True
    - require:
      - pkg: mongo_os_packages_requisites

mongodb:
  docker_container.running:
    - name: {{ mongodb.name }}
    - image: {{ mongodb.image }}
    {% for host in mongodb.bind_addresses %}
    - port_bindings:
      - {{ host }}:{{ mongodb.bind_port }}:{{ mongodb.container_port }}
    {% endfor %}
    - require:
      - service: {{ docker.service_name }}
      - pkg: mongo_in_docker_prerequisites
