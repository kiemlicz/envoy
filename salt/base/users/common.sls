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

{% if user.git.global_config %}
#https://github.com/saltstack/salt/issues/19869
{{ username }}_no_home_workaround:
  environ.setenv:
    - name: HOME
    - value: {{ user.home_dir }}
{% for k,v in user.git.global_config.items() %}
git_global_config_{{ username }}_{{ k }}:
  git.config_set:
    - name: {{ k }}
    - value: {{ v }}
    - user: {{ username }}
    - global: True
    - require:
      - user: {{ username }}
{% endfor %}
{% endif %}

{{ username }}_setup_ssh_known_hosts:
  ssh_known_hosts.present:
    - names: {{ user.ssh.known_hosts }}
    - user: {{ username }}
    - require:
      - user: {{ username }}

#todo setup backup policy

{% endfor %}
