{% from "erlang/map.jinja" import erlang with context %}

include:
  - pkgs

erlang:
{% if erlang.repo_entries is defined or erlang.repo_id is defined %}
  pkgrepo.managed:
{% if erlang.repo_entries is defined %}
    - names: {{ erlang.repo_entries|json_decode_list }}
    - file: {{ erlang.file }}
    - key_url: {{ erlang.key_url }}
    - require_in:
      - file: {{ erlang.apt_preferences_file }}
{% else %}
    - name: {{ erlang.repo_id }}
    - baseurl: {{ erlang.baseurl }}
    - humanname: {{ erlang.repo_id }}
    - gpgcheck: 1
    - gpgkey: {{ erlang.gpgkey }}
{% endif %}
    - require:
      - sls: pkgs
{% if erlang.repo_entries is defined %}
  file.managed:
    - name: {{ erlang.apt_preferences_file }}
    - source: salt://erlang/erlang.pref
    - require_in:
      - pkg: {{ erlang.pkg_name }}
{% endif %}
{% endif %}
  pkg.latest:
    - name: {{ erlang.pkg_name }}
    - refresh: True
    - require:
      - sls: pkgs
