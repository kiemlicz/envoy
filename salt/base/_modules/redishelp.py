import redis


def slots(pod_details_dict):
    r = redis.StrictRedis(host=pod_details_dict['ips'][0], port=pod_details_dict['port'])
    cluster_slots = r.cluster("slots")
    myid = r.cluster("myid")
    slots_lists = [range(one_range[0], one_range[1] + 1) for one_range in cluster_slots if myid in [client[2] for client in one_range[2:]]]
    pod_slots = [e for sublist in slots_lists for e in sublist]
    return pod_slots
