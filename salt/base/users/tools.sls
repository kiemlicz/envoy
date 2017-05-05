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
      - git: {{ username }}_setup_oh_my_zsh
{{ username }}_fzf:
  git.latest:
    - user: {{ username }}
    - name: {{ user.tools.fzf.url }}
    - target: {{ user.tools.fzf.target }}
    - force_fetch: True
    - require:
      - user: {{ username }}
  cmd.wait:
  # doesn't duplicate line appended to .zshrc
    - name: yes | {{ user.tools.fzf.target }}/install
    - runas: {{ username }}
    - require:
      - user: {{ username }}
      - git: {{ username }}_fzf
    - watch:
      - git: {{ username }}_fzf
{{ username }}_powerline:
#todo pip3 as well
  pkg.latest:
    - pkgs: {{ user.tools.powerline.required_pkgs }}
    - refresh: True
    - require:
      - user: {{ username }}
  pip.installed:
    - name: {{ user.tools.powerline.pip }}
    - user: {{ username }}
    - install_options:
      - --user
    - require:
      - user: {{ username }}
      - pkg: {{ username }}_powerline
  git.latest:
    - user: {{ username }}
    - name: {{ user.tools.powerline.url }}
    - target: {{ user.tools.powerline.target }}
    - force_fetch: True
    - require:
      - user: {{ username }}
      - pip: {{ username }}_powerline
  cmd.wait:
    - name: {{ user.tools.powerline.target }}/install.sh
    - runas: {{ username }}
    - watch:
      - git: {{ username }}_powerline
    - require:
      - user: {{ username }}
      - git: {{ username }}_powerline

{% endfor %}
