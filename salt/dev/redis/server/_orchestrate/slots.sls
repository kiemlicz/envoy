#!py


def run():
  states = {}
  if 'docker' in pillar['redis']:
    masters = [e['pod'] for e in pillar['redis']['docker'].get('masters', [])]
    desired_slots = pillar['redis']['slots']
    assigned_slots = {}
    for minion, pods_map in salt['mine.get'](tgt=grains['id'], fun="redis_pods").items():
      for pod_id, details in pods_map.items() if details['Labels']['io.kubernetes.pod.name'] in masters:
        master_pod_name = details['Labels']['io.kubernetes.pod.name']
        master_pod_details = salt.kubehelp.pod_info(master_pod_name, grains['id'])
        assigned_slots[master_pod_name] = salt.redishelp.slots(master_pod_details['ips'][0], pillar['redis']['port'])

    for master_pod_name, slots_list in assigned_slots.items():
      ???
  return states