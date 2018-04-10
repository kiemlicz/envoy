{% for username, user in salt['pillar.get']("users", {}).items() %}

{{ username }}_setup_user:
  user.present:
    - name: {{ username }}
    - fullname: {{ user.fullname }}
    - shell: {{ user.shell }}
    - home: {{ user.home_dir }}
    - require:
      - sls: mounts
      - sls: hosts
      - sls: pkgs
{% if user.groups is defined %}
  group.present:
    - names: {{ user.groups }}
    - addusers:
      - {{ username }}
{% endif %}
{{ username }}_setup_directories:
  file.directory:
    - user: {{ username }}
    - group: {{ username }}
    - mode: 755
    - makedirs: True
    - names: {{ user.user_dirs }}
    - require:
      - user: {{ username }}

{% if user.git is defined %}
#https://github.com/saltstack/salt/issues/19869
{{ username }}_no_home_workaround:
  environ.setenv:
    - name: HOME
    - value: {{ user.home_dir }}
{% for k,v in user.git.items() %}
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

{% if user.known_hosts is defined %}
{{ username }}_setup_ssh_known_hosts:
  ssh_known_hosts.present:
    - names: {{ user.known_hosts }}
    - user: {{ username }}
    - require:
      - user: {{ username }}
{% endif %}

{% endfor %}
