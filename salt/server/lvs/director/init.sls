{% from "lvs/map.jinja" import lvs with context %}
{% from "_common/util.jinja" import is_container with context %}


include:
  - pkgs
# -sls: keepalived

lvs_director:
  pkg.latest:
    - name: {{ lvs.pkg_name }}
    - require:
      - pkg: os_packages
  kmod.present:
    - name: {{ lvs.module }}
{% if not is_container()|to_bool %}
    - persist: {{ lvs.persist_module }}
{% endif %}
    - require:
      - pkg: {{ lvs.pkg_name }}
  #opts

{# to be used as sh fallback #}
{% for name,service in lvs.director.services.items() %}
lvs_director_{{ name }}:
  lvs_service.present:
    - name: {{ name }}
    - protocol: {{ service.protocol }}
    - service_address: {{ service.address }}
    - scheduler: {{ service.scheduler }}
    - require:
      - kmod: {{ lvs.module }}
{% endfor %}
