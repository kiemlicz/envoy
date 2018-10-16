#!jinja|stringpy

{% from "redis/server/map.jinja" import redis with context %}


def run():
  redis = {{ redis|json }}
  masters = [e["id"] for e in redis["instances"]["masters"]]
  slaves = [e["id"] for e in redis["instances"]["slaves"]]
  redis_minions = list(set(masters + slaves))

  slots = {}
  state = {}

  if redis["setup_type"] == "single":
    # no orchestration for single install type
    state['redis_orchestrate_disabled'] = {
      "salt.function": [
      # can invoke only module function
        { 'name': "test.true" },
        { 'tgt': '*' }
      ]
    }
    return state

  for i in range(0, redis['total_slots']):
    slots.setdefault(masters[i%len(masters)], []).append(i)

  state['redis_cluster_reset'] = {
    'salt.state': [
      { 'tgt': redis_minions },
      { 'tgt_type': "list" },
      { 'sls': [
        "redis.server.cluster._orchestrate.reset"
      ]},
      { 'saltenv': saltenv }
    ]
  }

  state['redis_cluster_meet'] = {
    'salt.state': [
      { 'tgt': redis_minions },
      { 'tgt_type': "list" },
      { 'sls': [
        "redis.server.cluster._orchestrate.meet"
      ]},
      { 'saltenv': saltenv },
      { 'require': [
         {'salt': "redis_cluster_reset"}
      ]}
    ]
  }

  state['redis_cluster_orchestrate'] = {
    'salt.state': [
      { 'tgt': redis_minions },
      { 'tgt_type': "list" },
      { 'sls': [
        "redis.server.cluster._orchestrate.slots",
        "redis.server.cluster._orchestrate.replicate"
      ]},
      { 'saltenv': saltenv },
      { 'pillar': {
          'redis': {
            'slots': slots
          }
        }
      },
      { 'require': [
        {'salt': "redis_cluster_meet"}
      ]}
    ]
  }

  return state