{% if data['fun'] == 'state.highstate' %}
{% set jobs = salt.saltutil.runner("jobs.list_jobs").items()|map(attribute=1)|selectattr("Function", "equalto", "state.highstate")|list %}
{% set completed_minions = jobs|map(attribute='Target')|unique %}
{# get minion names from pillar and compare lists instead of below dummy check #}
{% if completed_minions|length >= 3 %}

redis_orchestrate:
  runner.state.orchestrate:
    - tgt: {{ completed_minions }}
    - args:
      - mods: _orchestrate.redis.server.cluster.orch
      - saltenv: {{ saltenv }}}

{% endif %}
{% endif %}
