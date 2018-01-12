{% from "pkgs/map.jinja" import pkgs with context %}

include:
  - repositories

# any pkg.* that depends on this state for performance reasons, should not use refresh: True
pkgs:
  pkg.latest:
    - name: os_packages
    - pkgs: {{ pkgs.os_packages }}
    - refresh: True
    - reload_modules: True
    - require:
      - sls: repositories
  pip.installed:
    - name: pip_packages
    - pkgs: {{ pkgs.pip_packages }}
    - reload_modules: True
    - require:
      - pkg: os_packages
  cmd.wait:
    - names: {{ pkgs.post_install if pkgs.post_install is defined else [] }}
    - watch:
      - pkg: os_packages
