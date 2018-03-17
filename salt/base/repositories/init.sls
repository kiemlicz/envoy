{% from "repositories/map.jinja" import repositories with context %}


include:
  - locale

{% for repo in repositories.list %}
{{ repo.file }}_{{ repo.names|first }}_repository:
  pkgrepo.managed:
    - names: {{ repo.names }}
    - file: {{ repo.file }}
    {% if repo.key_url is defined %}
    - key_url: {{ repo.key_url }}
    {% endif %}
    # refresh on last configured repo
    - refresh_db: {{ True if repositories.list|last == repo else False }}
    - require:
      - sls: locale
{% endfor %}

{% for pref in repositories.preferences %}
{{ pref.file }}_repository:
  file.managed:
    - name: {{ pref.file }}
    - source: {{ repositories.preferences_template }}
    - template: jinja
    - makedirs: True
    - create: True
    - require:
      - sls: locale
    - context:
      pin: {{ pref.pin }}
      priority : {{ pref.priority }}
{% endfor %}
