#!py


def run():
  states = {}
  if 'docker' in pillar['redis']:
    for pod_name in grains['redis']['pods'] if pod_name in [e['pod'] for e in pillar['redis']['docker'].get('masters', [])]:
      pod_details = salt.mine.get(grains['id'], pod_name)
      #todo lua script to output nicely slot to instance assignments
