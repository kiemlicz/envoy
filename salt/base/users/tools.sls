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

{{ username }}_powerline_requirements:
  pkg.latest:
    - pkgs: {{ user.tools.powerline.required_pkgs }}
    - refresh: True
    - require:
      - user: {{ username }}
{{ username }}_powerline_python2:
  pip.installed:
    - name: {{ user.tools.powerline.pip }}
    - user: {{ username }}
    - install_options:
      - --user
    - require:
      - user: {{ username }}
      - pkg: {{ username }}_powerline_requirements
{{ username }}_powerline_python3:
  pip.installed:
    - name: {{ user.tools.powerline.pip }}
    - user: {{ username }}
    - bin_env: '/usr/bin/pip3'
    - install_options:
      - --user
    - require:
      - user: {{ username }}
      - pkg: {{ username }}_powerline_requirements
{{ username }}_powerline_fonts:
  git.latest:
    - user: {{ username }}
    - name: {{ user.tools.powerline.url }}
    - target: {{ user.tools.powerline.target }}
    - force_fetch: True
    - require:
      - user: {{ username }}
      - pip: {{ username }}_powerline_python3
      - pip: {{ username }}_powerline_python2
  cmd.wait:
    - name: {{ user.tools.powerline.target }}/install.sh
    - runas: {{ username }}
    - watch:
      - git: {{ username }}_powerline_fonts
    - require:
      - user: {{ username }}
      - git: {{ username }}_powerline_fonts

{% endfor %}
