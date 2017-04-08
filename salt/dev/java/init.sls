{% from "java/map.jinja" import java with context %}
{% from "_macros/dev_tool.macros.jinja" import add_environmental_variable,add_to_path with context %}

include:
  - pkgs

java:
{% if grains['os'] != 'Windows' %}
  pkgrepo.managed:
    - names: {{ java.repo_entries }}
    - file: {{ java.file }}
    - keyid: {{ java.keyid }}
    - keyserver: {{ java.keyserver }}
    - require_in:
      - debconf: {{ java.pkg_name }}
  debconf.set:
    - name: {{ java.pkg_name }}
    - data:
        'shared/accepted-oracle-license-v1-1': {'type': 'boolean', 'value': True}
    - require_in:
      - pkg: {{ java.pkg_name }}
{% endif %}
  pkg.latest:
    - name: {{ java.pkg_name }}
    - pkgs: {{ [ java.pkg_name ] + java.ext_pkgs }}
    - refresh: True
    - require:
      - sls: pkgs
{{ add_environmental_variable(java.environ_variable, java.generic_link, java.exports_file) }}
{{ add_to_path(java.environ_variable, java.path_inside, java.exports_file) }}

#todo windows: like sbt - detect dir for JAVA_HOME