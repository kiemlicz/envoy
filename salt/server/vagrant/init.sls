{% from "vagrant/map.jinja" import vagrant with context %}


include:
  - os


{% if vagrant.requisites is defined %}
vagrant_requisites:
  pkg.latest:
    - pkgs: {{ vagrant.requisites }}
    - require:
      - sls: os
    - require_in:
      - pkg: vagrant
{% endif %}

vagrant:
  pkg.installed:
    - sources: {{ vagrant.sources }}
    - refresh: True
    - reload_modules: True
    - require:
      - sls: os

{% if vagrant.plugins is defined %}
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
  - name: "vagrant plugin install {{ plugin.name }}"
  - require:
    - pkg: vagrant

{% endfor %}
{% endif %}
