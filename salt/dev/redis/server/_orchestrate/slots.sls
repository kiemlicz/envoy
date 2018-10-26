#!py


def run():
  states = {}
  #todo docker differentiation is not needed here
  #todo rethink minion: redis instances arity
  if 'docker' in pillar['redis']:
    masters = [e['pod'] for e in pillar['redis']['docker'].get('masters', [])]
    names_map =  {}
    for minion, pods_map in salt['mine.get'](tgt="*", fun="redis_pods").items():
      for pod_id, details in pods_map.items():
        if details['Labels']['io.kubernetes.pod.name'] in masters:
          master_pod_name = details['Labels']['io.kubernetes.pod.name']
          master_pod_details = salt.kubehelp.pod_info(master_pod_name, minion)
          master_pod_details['port'] = pillar['redis']['port']
          names_map[master_pod_name] = master_pod_details

    states['redis_cluster_slots_manage'] = {
      'redis_ext.slots_manage': [
        { 'name': "slots" },
        { 'names_map': names_map },
        { 'desired_slots': pillar['redis']['slots'] }
      ]
    }

  return states
