{% set tag = salt.pillar.get('event_tag') %}
{% set data = salt.pillar.get('event_data') %}

redis_cluster_meet:
  test.show_notification:
    - name: reaction
    - text: {{ data }}
