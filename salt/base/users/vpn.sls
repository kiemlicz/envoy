{% for username in pillar['users'].keys() if pillar['users'][username].vpn is defined %}
{% set user = pillar['users'][username] %}

{% for v in user.vpn %}
{% set vpn_config = '{}_vpn_{}_config'.format(username, v.name) %}

{% if pillar[vpn_config] is defined or v.config is defined or v.source is defined %}
{{ username }}_vpn_{{ v.name }}_config:
  file_ext.managed:
    - name: {{ v.location }}/{{ v.name }}
{% if pillar[vpn_config] is defined %}
    - contents_pillar: {{ vpn_config }}
{% elif v.source is defined %}
    - source: {{ v.source }}
{% else %}
    - contents: {{ v.config | yaml_encode }}
{% endif %}
    - user: {{ username }}
    - mode: 600
    - makedirs: True
    - require:
      - user: {{ username }}
{% endif %}

{% endfor %}
{# somehow empty notification is not needed here #}
{% endfor %}
