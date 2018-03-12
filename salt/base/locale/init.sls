{% from "locale/map.jinja" import locale with context %}
{% from "_common/util.jinja" import is_lxc with context %}

required_pkgs:
  pkg.latest:
    - pkgs: {{ locale.required_pkgs }}

gen_locale:
  locale.present:
    - names: {{ locale.locales }}
    - require:
      - pkg: required_pkgs

{% if not is_lxc()|to_bool %}
default_locale:
  locale.system:
    - name: {{ locale.system_default }}
    - require:
      - locale: gen_locale
{% endif %}
