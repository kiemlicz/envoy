{% from "keepass/map.jinja" import keepass with context %}

include:
  - pkgs

# todo gpgcheck:1 in pkgrepo.managed
# todo mind windows

keepass:
  pkg.installed:
    - sources:
      - {{ keepass.pkg_name }}: {{ keepass.url }}
    - require:
      - sls: pkgs
