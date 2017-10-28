{% from "mongodb/map.jinja" import setup_type with context %}

{% if setup_type == 'repo' %}

include:
  - mongodb.server.repo

{% elif setup_type == 'docker' %}

include:
  - docker
  - mongodb.server.docker

{% endif %}

# todo add conf/log/db_path file management