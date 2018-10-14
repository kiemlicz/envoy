{% from "vagrant/map.jinja" import vagrant with context %}


include:
  - os


vagrant:
  pkg.latest:
    - sources: {{ vagrant.sources }}
    - refresh: True
    - reload_modules: True
    - require:
      - sls: os
