{% for username in pillar['users'].keys() %}
{% set user = pillar['users'][username] %}

# todo Jinja2.9, remove this pathetic loop over user.sec.ssh and use directly in state:
{# - identity: {{ user.sec.ssh|selectattr("name", "equalto", "dotfile")|map(attribute='privkey_location')|first }} #}

{% for key_spec in user.sec.ssh %}
{% if key_spec.name == 'dotfile' %}

{{ username }}_dotfiles:
  dotfile.managed:
    - require:
      - sls: users.common
      - sls: users.tools
      - sls: users.keys
      - user: {{ username }}
    - name: {{ user.dotfile.repo }}
    - home_dir: {{ user.home_dir }}
    - username: {{ username }}
    - branch: {{ user.dotfile.branch }}
    - target: {{ user.dotfile.root }}
    - identity: {{ key_spec.privkey_location }}
    - saltenv: {{ saltenv }}
#todo fallback location = home
{% if user.dotfile.post_cmd is defined %}
  cmd.wait:
    - name: {{ user.dotfile.post_cmd }}
    - runas: {{ username }}
    - cwd: {{ user.dotfile.root }}
    - watch:
      - dotfile: {{ user.dotfile.repo }}
{% endif %}

{% endif %}
{% endfor %}


{% endfor %}
