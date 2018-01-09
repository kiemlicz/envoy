#!py


def run():
  masters = [e["host_id"] for e in __pillar__["redis"]["master_bind_list"]]
  slaves = [e["host_id"] for e in __pillar__["redis"]["slave_bind_list"]]
  redis_minions = list(set(masters + slaves))
  #todo come up with idea how to import in #!py jinja template
  redis_cluster = __salt__['grains.filter_by']({
    'default': {
      'total_slots': 16384,
    }
  }, merge=__salt__['pillar.get']('redis_cluster'))
  slots = {}
  state = {}

  for i in range(0, redis_cluster['total_slots']):
    slots.setdefault(masters[i%len(masters)], []).append(i)

  state['redis_cluster_reset'] = {
    'salt.state': [
      { 'tgt': redis_minions },
      { 'tgt_type': "list" },
      { 'sls': [
          "redis.server.cluster.reset"
      ]},
      { 'saltenv': saltenv }
    ]
  }

  state['redis_cluster_orchestrate'] = {
    'salt.state': [
      { 'tgt': redis_minions },
      { 'tgt_type': "list" },
      { 'sls': [
        "redis.server.cluster.meet",
        "redis.server.cluster.replicate"
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
