#!py


def run():
  states = {}
  #todo docker differentiation is not needed here
  #todo rethink minion: redis instances arity
  if 'docker' in pillar['redis']:
    masters_names = [e['pod'] for e in pillar['redis']['docker'].get('masters', [])]
    names_map = salt['kube_ext.app_info']("redis-cluster")
    for name, details in names_map.items():
      details['port'] = pillar['redis']['port']

    states['redis_cluster_slots_manage'] = {
      'redis_ext.slots_manage': [
        { 'name': "redis_cluster_slots_manage" },
        { 'nodes_map': names_map },
        { 'min_nodes': pillar['redis']['size'] },
        { 'master_names': masters_names },
        { 'total_slots': pillar['redis']['total_slots'] }
      ]
    }

  return states
