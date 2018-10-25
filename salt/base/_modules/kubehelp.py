

def pod_info(pod_name, owning_minion):
    ret = {}
    pod_details = __salt__['mine.get'](tgt=owning_minion, fun=pod_name)
    pod_envs = pod_details[owning_minion]['Config']['Env']
    container_ip_list = [e.split("=")[1] for e in __salt__['filters.find'](pod_envs, "POD_IP=\d+\.\d+\.\d+\.\d+")]
    container_id = pod_details[owning_minion]["Id"]
    ret['id'] = container_id
    ret['ips'] = container_ip_list
    return ret
