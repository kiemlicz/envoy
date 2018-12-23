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

{% for plugin in vagrant.plugins %}

vagrant_plugin_{{ plugin.name }}:
{% if plugin.pkgs is defined %}
  pkg.latest:
  - pkgs: {{ plugin.pkgs }}
  - require:
    - pkg: vagrant
  - require_in:
    - cmd: vagrant_plugin_{{ plugin.name }}
{% endif %}
  cmd.run:
  - name: "vagrant plugin install " ~ {{ plugin.name }}
  - require:
    - pkg: vagrant

{% endfor %}
