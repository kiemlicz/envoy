{% for username in pillar['users'].keys() %}
{% set user = pillar['users'][username] %}

{% if user.vpn is defined %}
{% for v in user.vpn %}

{% set vpn_config = '{}_vpn_{}_config'.format(username, v.name) %}

{% if pillar[vpn_config] is defined or v.config is defined %}
{{ username }}_vpn_{{ v.name }}_config:
  file.managed:
    - name: {{ v.location }}/{{ v.name }}
{% if pillar[vpn_config] is defined %}
    - contents_pillar: {{ vpn_config }}
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
{% endif %}
{% endfor %}
