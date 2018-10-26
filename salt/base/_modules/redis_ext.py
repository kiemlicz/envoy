import logging

try:
    import redis

    HAS_REDIS = True
except ImportError:
    HAS_REDIS = False

log = logging.getLogger(__name__)


def __virtual__():
    return True if HAS_REDIS else (False, "Cannot load redis.ext, install: redis")


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
        'failed': []
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
