{% from "nvidia/map.jinja" import nvidia with context %}

include:
  - repositories
  - pkgs


# install nvidia proprietary driver from repo
nvidia_driver:
  pkg.latest:
    - pkgs: {{ nvidia.pkgs }}
    - refresh: True
    - require:
      - sls: repositories
    - require_in:
      - pkg: pkgs
