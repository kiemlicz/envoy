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
    - post_state_cmd: {{ user.dotfile.post_cmd }}
#todo fallback location = home

{% endif %}
{% endfor %}


{% endfor %}
