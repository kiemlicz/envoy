{% for username in pillar['users'].keys() %}
{% set user = pillar['users'][username] %}

{{ username }}_setup_oh_my_zsh:
  git.latest:
    - user: {{ username }}
    - name: {{ user.tools.oh_my_zsh.url }}
    - target: {{ user.tools.oh_my_zsh.target }}
    - force_fetch: True
    - require:
      - user: {{ username }}
{{ username }}_setup_oh_my_zsh_syntax_highlighting:
  git.latest:
    - user: {{ username }}
    - name: {{ user.tools.oh_my_zsh_syntax_highlighting.url }}
    - target: {{ user.tools.oh_my_zsh_syntax_highlighting.target }}
    - force_fetch: True
    - require:
      - user: {{ username }}
{{ username }}_fzf:
  git.latest:
    - user: {{ username }}
    - name: {{ user.tools.fzf.url }}
    - target: {{ user.tools.fzf.target }}
    - force_fetch: True
    - require:
      - user: {{ username }}
  cmd.run:
  # will duplicate entry in zshrc
    - name: yes | {{ user.tools.fzf.target }}/install
    - runas: {{ username }}
    - require:
      - user: {{ username }}
{{ username }}_powerline:
#todo pip3 as well
  pip.installed:
    - name: {{ user.tools.powerline.pip }}
    - user: {{ username }}
    - install_options:
      - --user
    - require:
      - user: {{ username }}
  git.latest:
    - user: {{ username }}
    - name: {{ user.tools.powerline.url }}
    - target: {{ user.tools.powerline.target }}
    - force_fetch: True
    - require:
      - user: {{ username }}
  cmd.run:
    - name: {{ user.tools.powerline.target }}/install.sh
    - runas: {{ username }}
    - require:
      - user: {{ username }}

{% endfor %}
