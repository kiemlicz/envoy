{% from "nvidia/map.jinja" import nvidia with context %}

include:
  - os.repositories
  - os.pkgs


# install nvidia proprietary driver from repo
nvidia_driver:
  pkg.latest:
    - pkgs: {{ nvidia.pkgs }}
    - refresh: True
    - require:
      - sls: os.repositories
    - require_in:
      - pkg: os.pkgs
