#!py


def run():
  states = {}
  if 'docker' in pillar['redis']:
    masters = [e['pod'] for e in pillar['redis']['docker'].get('masters', [])]
    for minion, pods_map in salt['mine.get'](tgt=grains['id'], fun="redis_pods").items():
      for pod_id, details in pods_map.items() if details['Labels']['io.kubernetes.pod.name'] in masters:
        master_pod_details = salt.kubehelp.pod_info(details['Labels']['io.kubernetes.pod.name'], grains['id'])
        master_pod_details['port'] = pillar['redis']['port']
        master_pod_details['slots'] = salt.redishelp.slots(master_pod_details)

  return states