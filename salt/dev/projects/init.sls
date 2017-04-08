include:
  - users

{% for username in pillar['users'].keys() %}
{% set user = pillar['users'][username] %}

{% for project in user.projects %}


{% if "git" in project.url %}
{{ username }}_git_clone_{{ project.url }}:
  git.latest:
    - name: {{ project.url }}
    - user: {{ username }}
    - target: {{ project.target }}
{% if project.identity is defined %}
    - identity: {{ project.identity }}
{% endif %}
    - require:
      - user: {{ username }}

{% elif "hg" in project.url %}
{{ username }}_hg_clone_{{ project.url }}:
  hg.latest:
    - name: {{ project.url }}
    - user: {{ username }}
    - target: {{ project.target }}
{% if project.identity is defined %}
    - identity: {{ project.identity }}
{% else %}
    - opts: --insecure
{% endif %}
    - require:
      - user: {{ username }}
{% endif %}

#todo switch to branch
#todo copy custom files

{% endfor %}

{% endfor %}
