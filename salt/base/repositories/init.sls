{% from "repositories/map.jinja" import repositories with context %}

{% for repo in repositories.list %}
{{ repo.file }}_repository:
  pkgrepo.managed:
    - names: {{ repo.names }}
    - file: {{ repo.file }}
    {% if repo.key_url is defined %}
    - key_url: {{ repo.key_url }}
    {% endif %}
    - refresh_db: True
    - require_in:
      - file: empty_sources_list
{% endfor %}

{% for pref in repositories.preferences %}
{{ pref.file }}_repository:
  file.managed:
    - name: {{ pref.file }}
    - source: {{ repositories.preferences_template }}
    - template: jinja
    - makedirs: True
    - create: True
    - context:
      pin: {{ pref.pin }}
      priority : {{ pref.priority }}
{% endfor %}

#salt has problem with managing duplicated entries...
#this is why we wipe out useless sources.list
{% if repositories.list %}
empty_sources_list:
  file.managed:
    - name: {{ repositories.sources_list_location }}
    - contents: ''
    - replace: True
{% else %}
empty-repositories-notification:
  test.show_notification:
    - name: No repositories
    - text: "No repositories configured as none specified"
{% endif %}
