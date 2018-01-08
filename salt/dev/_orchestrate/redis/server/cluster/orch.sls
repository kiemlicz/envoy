#!py


def run():
  masters = [e["host_id"] for e in __pillar__["redis"]["master_bind_list"]]
  slaves = [e["host_id"] for e in __pillar__["redis"]["slave_bind_list"]]
  redis_minions = list(set(masters + slaves))
  total_slots = 16383
  #fixme come up with idea how to import in #!py jinja template
  slots = {}
  state = {}

  for i in range(0, total_slots):
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
