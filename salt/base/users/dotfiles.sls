{% for username in pillar['users'].keys() %}
{% set user = pillar['users'][username] %}

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
    - identity: {{ user.sec.ssh|selectattr("name", "equalto", "dotfile")|map(attribute='privkey_location')|first }}
    - saltenv: {{ saltenv }}
#todo fallback location = home
{% if user.dotfile.post_cmds is defined %}
  cmd.wait:
    - names: {{ user.dotfile.post_cmds }}
    - runas: {{ username }}
    - cwd: {{ user.dotfile.root }}
    - watch:
      - dotfile: {{ user.dotfile.repo }}
{% endif %}

{% endfor %}
