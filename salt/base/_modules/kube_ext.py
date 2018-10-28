

def pod_info(pod_name, owning_minion):
    ret = {}
    pod_details = __salt__['mine.get'](tgt=owning_minion, fun=pod_name)
    pod_envs = pod_details[owning_minion]['Config']['Env']
    container_ip_list = [e.split("=")[1] for e in __salt__['filters.find'](pod_envs, "POD_IP=\d+\.\d+\.\d+\.\d+")]
    container_id = pod_details[owning_minion]["Id"]
    ret['id'] = container_id
    ret['ips'] = container_ip_list
    return ret


def app_info(fun_name):
    '''

    :param fun_name: mined function that already returns docker.ps output
    :return: dict {'pod1': {ips: [], id="", minion=""}}
    '''
    ret = {}
    for minion, details in __salt__['mine.get'](tgt="*", fun=fun_name).items():
        pod_name = details['Labels']['io.kubernetes.pod.name']
        pod_envs = details['Config']['Env']
        pod_ip_list = [e.split("=")[1] for e in __salt__['filters.find'](pod_envs, "POD_IP=\d+\.\d+\.\d+\.\d+")]
        # todo parse ports
        ret[pod_name] = {
            'ips': pod_ip_list,
            'minion': minion
        }

    return ret
