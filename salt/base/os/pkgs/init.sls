{% from "os/pkgs/map.jinja" import pkgs with context %}
{% from "_common/util.jinja" import retry with context %}

{% if pkgs.dist_upgrade %}
dist-upgrade:
  pkg.uptodate:
    - name: upgrade_os
    - refresh: True
    - force_yes: True
    - require:
      - sls: os.locale
    - require_in:
      - pkg: os_packages
{% endif %}

# any pkg.* that depends on this state for performance reasons, should not use refresh: True
pkgs:
  pkg.latest:
    - name: os_packages
    - pkgs: {{ pkgs.os_packages }}
    - refresh: True
    - reload_modules: True
    - require:
      - sls: os.locale

{% if pkgs.sources is defined %}
pkgs_sources:
  pkg.installed:
    - sources: {{ pkgs.sources }}
    - require:
      - pkg: upgrade_os
    - require_in:
      - pip: pip_packages
    - onchanges_in:
      - cmd: post_install
{{ retry(attempts=2)| indent(4) }}
{% endif %}

pkgs_pip:
  pip.installed:
    - name: pip_packages
    - pkgs: {{ pkgs.pip_packages }}
    - reload_modules: True
    - require:
      - pkg: os_packages

{% if pkgs.scripts is defined %}
{% for script in pkgs.scripts %}
pkgs_scripts:
  cmd.script:
    - name: {{ script.source }}
    - args: {{ script.args }}
    - require:
      - pip: pip_packages
{% endfor %}
{% endif %}

{% if pkgs.post_install is defined and pkgs.post_install %}
post_install:
  cmd.run:
    - names: {{ pkgs.post_install }}
    - require:
      - pip: pip_packages
    - onchanges:
      - pkg: os_packages
{% endif %}
