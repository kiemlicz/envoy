#!py


#no easy way to import map.jinja in py renderer
#https://github.com/saltstack/salt/issues/45521
def _map():
  return __salt__.grains.filter_by({
        'default': {
          'total_slots': 16384,
        }
      }, merge=__salt__.pillar.get('redis'))

def run():
  redis = _map()
  masters = [e["id"] for e in redis["masters"]]
  slaves = [e["id"] for e in redis["slaves"]]
  redis_minions = list(set(masters + slaves))

  slots = {}
  state = {}

  if __pillar__["redis"]["setup_type"] == "single":
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

  state['redis_cluster_orchestrate'] = {
    'salt.state': [
      { 'tgt': redis_minions },
      { 'tgt_type': "list" },
      { 'sls': [
        "redis.server.cluster._orchestrate.meet",
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
        {'salt': "redis_cluster_reset"}
      ]}
    ]
  }

  return state
