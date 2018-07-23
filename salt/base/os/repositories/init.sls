{% from "os/repositories/map.jinja" import repositories with context %}
{% from "_common/util.jinja" import retry with context %}

{% for repo in repositories.list %}
{{ repo.file }}_{{ repo.names|first }}_repository:
  pkgrepo_ext.managed:
{% if repo.names is defined %}
    - names: {{ repo.names|json_decode_list }}
    - file: {{ repo.file }}
    {% if repo.key_url is defined %}
    - key_url: {{ repo.key_url }}
    {% elif repo.keyid is defined %}
    - keyid: {{ repo.keyid }}
    - keyserver: {{ repo.keyserver }}
    {% endif %}
    # refresh on last configured repo
    - refresh_db: {{ True if repositories.list|last == repo else False }}
{% else %}
    - name: {{ repo.repo_id }}
    - baseurl: {{ repo.baseurl }}
    - humanname: {{ repo.repo_id }}
    - gpgcheck: 1
    - gpgkey: {{ repo.gpgkey }}
{% endif %}
{{ retry()| indent(4) }}
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

repositories-notification:
  test.show_notification:
    - name: Repositories setup completed
    - text: "Repositories setup completed"
