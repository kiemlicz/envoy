{% for username in pillar['users'].keys() %}
{% set user = pillar['users'][username] %}

{{ username }}_setup_user:
  user.present:
    - name: {{ username }}
    - fullname: {{ user.fullname }}
    - shell: {{ user.shell }}
    - home: {{ user.home_dir }}
    - require:
      - sls: pkgs
      - sls: mounts
      - sls: hosts
  group.present:
    - names: {{ user.groups }}
    - addusers:
      - {{ username }}
{{ username }}_setup_directories:
  file.directory:
    - user: {{ username }}
    - group: {{ username }}
    - mode: 755
    - makedirs: True
    - names: {{ user.user_dirs }}
    - require:
      - user: {{ username }}

{% if user.git_username_global is defined and user.git_mail_global is defined %}
#https://github.com/saltstack/salt/issues/19869
{{ username }}_no_home_workaround:
  environ.setenv:
    - name: HOME
    - value: {{ user.home_dir }}
{{ username }}_setup_git_global_username:
  git.config_set:
    - name: user.name
    - value: {{ user.git_username_global }}
    - user: {{ username }}
    - global: True
    - require:
      - user: {{ username }}
{{ username }}_setup_git_global_email:
  git.config_set:
    - name: user.email
    - value: {{ user.git_mail_global }}
    - user: {{ username }}
    - global: True
    - require:
      - user: {{ username }}
{% endif %}

{% if user.git_ignore is defined %}
{{ username }}_setup_git_ignore:
  file.managed:
    - name: {{ user.home_dir }}/.gitignore
    - contents: {{ user.git_ignore }}
    - user: {{ username }}
    - group: {{ username }}
    - require:
      - user: {{ username }}
{% endif %}

{{ username }}_setup_ssh_known_hosts:
  ssh_known_hosts.present:
    - names: {{ user.ssh.known_hosts }}
    - user: {{ username }}
    - require:
      - user: {{ username }}

#todo setup backup policy

{% endfor %}
