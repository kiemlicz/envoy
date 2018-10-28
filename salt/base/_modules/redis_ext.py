import logging

try:
    import redis

    HAS_REDIS = True
except ImportError:
    HAS_REDIS = False

log = logging.getLogger(__name__)


def __virtual__():
    return True if HAS_REDIS else (False, "Cannot load redis.ext, install: redis")


def meet(ip, port, others):
    try:
        r = redis.StrictRedis(host=ip, port=port)
        for host_port in others:
            other_ip = host_port[0]
            other_port = host_port[1]
            r.cluster("meet", other_ip, other_port)
    except Exception as e:
        log.error("Cluster meet from {}:{} failed".format(ip, port))
        log.exception(e)
        return False
    return True


def replicate(master_ip, master_port, slave_ip, slave_port):
    try:
        r = redis.StrictRedis(host=slave_ip, port=slave_port)
        m = redis.StrictRedis(host=master_ip, port=master_port)
        master_id = m.cluster("myid")
        r.cluster("replicate", master_id)
    except Exception as e:
        log.error("Cluster replicate (slave: {}:{}, master {}:{}) failed".format(slave_ip, slave_port, master_ip, master_port))
        log.exception(e)
        return False
    return True


def slots(ip, port):
    '''
    :return: slots belonging to this redis instance (doesn't matter if the instance is either slave or master)
    '''
    r = redis.StrictRedis(host=ip, port=port)
    cluster_slots = r.cluster("slots")
    myid = r.cluster("myid")
    slots_lists = [range(one_range[0], one_range[1] + 1) for one_range in cluster_slots if
                   myid in [client[2] for client in one_range[2:]]]
    pod_slots = [e for sublist in slots_lists for e in sublist]
    return pod_slots


def migrate(src_ip, src_port, dest_ip, dest_port, slot_list, batch_size=100):
    '''
    Migrates slots from source to destination
    '''
    ret = {
        'migrated': [],
        'failed': [],
        'result': False
    }
    if len(slot_list) == 0:
        return ret

    src = redis.StrictRedis(host=src_ip, port=src_port)
    src_id = src.cluster("myid")
    dest = redis.StrictRedis(host=dest_ip, port=dest_port)
    dest_id = dest.cluster("myid")
    for slot in slot_list:
        try:
            dest.cluster("setslot", slot, "importing", src_id)
            src.cluster("setslot", slot, "migrating", dest_id)
            while True:
                keys_to_migrate = src.cluster("getkeysinslot", slot, batch_size)
                src.execute_command("migrate", dest_ip, dest_port, "", 0, 5000, "keys", *keys_to_migrate)
                if len(keys_to_migrate) < batch_size:
                    break
            dest.cluster("setslot", slot, "node", dest_id)
            src.cluster("setslot", slot, "node", dest_id)
            ret['migrated'].append(slot)
        except Exception as e:
            log.error("Slot {} failed to migrate ({}:{} -> {}:{})".format(slot, src_ip, src_port, dest_ip, dest_port))
            log.exception(e)
            ret['failed'].append(slot)

    if len(ret['failed']) > 0:
        return ret
    else:
        ret['result'] = True
        return ret


def addslots(ip, port, slots):
    if len(slots) == 0:
        return True
    r = redis.StrictRedis(host=ip, port=port)
    try:
        r.cluster("addslots", *slots)
    except Exception as e:
        log.error("Unable to add slots: {} ({}:{})".format(slots, ip, port))
        log.exception(e)
        return False
    return True
