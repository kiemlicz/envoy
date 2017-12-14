{% if data['fun'] == 'state.highstate' %}
{# todo assert result == true!!!!!!! #}
{% set jobs = salt['saltutil.runner']("jobs.list_jobs").items()|map(attribute=1)|selectattr("Function", "equalto", "state.highstate")|list %}

{% set completed_minions = jobs|map(attribute='Target')|unique %}

{# expected minions (each to have any number of redis instances) #}
{% set masters =  %}
{# set expected_minions = salt['pillar.get']()       #}

{# highstate completes on minion . #}

{% if completed_minions|compare_lists(expected_minions)|length == 0 %}
# tgt: some more sophisticated targeting?
# extra args passing to orch.sls?
redis_orchestrate:
  runner.state.orchestrate:
    - tgt: {{ completed_minions }}
    - args:
      - mods: _orchestrate.redis.server.cluster.orch
      - saltenv: {{ saltenv }}}
      - pillar:
          tgt: {{ completed_minions }}

{% endif %}
{% endif %}
