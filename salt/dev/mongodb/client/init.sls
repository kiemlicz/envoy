{% from "mongodb/client/map.jinja" import mongodb_client with context as mongodb %}

include:
  - pkgs

mongodb_client:
  pkg.latest:
    - name: {{ mongodb.pkg_name }}
    - refresh: True
    - require:
      - pkg: os_packages
