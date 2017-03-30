{% from "locale/map.jinja" import locale with context %}

include:
  - repositories

required_pkgs:
  pkg.latest:
    - pkgs: {{ locale.required_pkgs }}
    - require_in:
      - locale: {{ locale.system_default }}

gen_locale:
  locale.present:
    - names: {{ locale.locales }}
    - require_in:
      - locale: {{ locale.system_default }}

default_locale:
  locale.system:
    - name: {{ locale.system_default }}
