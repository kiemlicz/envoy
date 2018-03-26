{% from "mongodb/server/single/map.jinja" import mongodb with context %}


#mongodb client is installed without adding mongodb repo - thus causes conflicts with official mongo repo
exclude:
  - id: mongodb_client

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
  file_ext.managed:
    - name: {{ mongodb.config.init_location }}
    - source: {{ mongodb.config.init }}
    - mode: {{ mongodb.config.mode }}
    - template: jinja
    - context:
      mongodb: {{ mongodb }}
    - require:
      - pkg: {{ mongodb.pkg_name }}
