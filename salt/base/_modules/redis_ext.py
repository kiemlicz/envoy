import logging
import copy

try:
    import redis
    from redis.exceptions import ResponseError

    HAS_REDIS = True
except ImportError:
    HAS_REDIS = False

log = logging.getLogger(__name__)


def __virtual__():
    return True if HAS_REDIS else (False, "Cannot load redis_ext, install: redis")


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
        s = redis.StrictRedis(host=slave_ip, port=slave_port)
        m = redis.StrictRedis(host=master_ip, port=master_port)
        master_id = m.cluster("myid")
        s.cluster("replicate", master_id)
    except Exception as e:
        log.error("Cluster replicate (slave: {}:{}, master {}:{}) failed".format(slave_ip, slave_port, master_ip, master_port))
        log.exception(e)
        return False
    return True


def migrate(src_ip, src_port, dest_ip, dest_port, slot_list, batch_size=100, migrate_timeout=20000):
    '''
    Migrates slots from source to destination
    '''
    ret = {
        'migrated': [],
        'failed': [],
        'result': False
    }
    if len(slot_list) == 0:
        # if there is nothing to migrate then is it success
        ret['result'] = True
        return ret
    # todo assert that slots are migrated and no node contains slots in improper state
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
                if keys_to_migrate:
                    src.execute_command("migrate", dest_ip, dest_port, "", 0, migrate_timeout, "keys", *keys_to_migrate)
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


def slots(ip, port):
    '''
    :return: slots belonging to this redis instance (doesn't matter if the instance is either slave or master)
    '''
    r = redis.StrictRedis(host=ip, port=port)
    cluster_slots = r.cluster("slots")
    myid = r.cluster("myid")
    slots_lists = [range(one_range[0], one_range[1] + 1) for one_range in cluster_slots if
                   myid in [client[2] for client in one_range[2:]]]
    instance_slots = [e for sublist in slots_lists for e in sublist]
    return instance_slots


def addslots(ip, port, slots):
    if len(slots) == 0:
        return True
    try:
        r = redis.StrictRedis(host=ip, port=port)
        r.cluster("addslots", *slots)
    except Exception as e:
        log.error("Unable to add slots: {} ({}:{})".format(slots, ip, port))
        log.exception(e)
        return False
    return True


def delslots(ip, port, slots):
    if len(slots) == 0:
        return True
    try:
        r = redis.StrictRedis(host=ip, port=port)
        r.cluster("delslots", *slots)
    except Exception as e:
        log.error("Unable to del slots: {} ({}:{})".format(slots, ip, port))
        log.exception(e)
        return False
    return True


def reset(ip, port, hard=False):
    try:
        r = redis.StrictRedis(host=ip, port=port)
        if hard:
            r.cluster("reset", "hard")
        else:
            r.cluster("reset")
    except Exception as e:
        log.error("Unable to cluster reset instance: ({}:{})".format(ip, port))
        log.exception(e)
        return False
    return True


def flushall(ip, port):
    try:
        r = redis.StrictRedis(host=ip, port=port)
        r.flushall()
    except Exception as e:
        log.error("Unable to flushall instance: ({}:{})".format(ip, port))
        log.exception(e)
        return False
    return True


def nodes(ip, port):
    try:
        r = redis.StrictRedis(host=ip, port=port)
        return r.cluster("nodes")
    except Exception as e:
        log.error("Unable to list cluster nodes ({}:{})".format(ip, port))
        log.exception(e)
        return {}


def failover(ip, port, arg=None):
    try:
        r = redis.StrictRedis(host=ip, port=port)
        if arg is None:
            r.cluster("failover")
        else:
            r.cluster("failover", arg)
    except Exception as e:
        log.error("Unable to failover on instance: ({}:{})".format(ip, port))
        log.exception(e)
        return False
    return True


def forget(ip, port, ids):
    try:
        r = redis.StrictRedis(host=ip, port=port)
        for id in ids:
            try:
                r.cluster("forget", id)
            except ResponseError as e:
                # if unknown then surely forgotten
                if not "Unknown node" in str(e):
                    raise
    except Exception as e:
        log.error("Unable to forget: {} on instance: ({}:{})".format(ids, ip, port))
        log.exception(e)
        return False
    return True


def role(ip, port):
    try:
        r = redis.StrictRedis(host=ip, port=port)
        return r.execute_command('role')[0]
    except Exception as e:
        log.error("Cannot fetch role of {}:{}".format(ip, port))
        log.exception(e)
        return None


def validate_slots(instances, cidr=None):
    local = copy.deepcopy(instances)
    s = {}
    for name, details in local.items():
        ip, port = ip_port(instances, name, cidr)
        if 'master' == role(ip, port):
            s[name] = slots(ip, port)

    for name, a in s.items():
        for other_name, b in {k: v for k, v in s.items() if k != name}.items():
            overlap = set(a) & set(b)
            if overlap:
                log.warn("Instances: {} and {} contain overlapping slots: {}".format(name, other_name, overlap))
                return False
    return True


def ip_port(instances, name, cidr):
    def _filter_ip(ips, cidr):
        if cidr:
            return [e for e in ips if __salt__['network.ip_in_subnet'](e, cidr)]
        else:
            return ips

    return _filter_ip(instances[name]['ips'], cidr)[0], instances[name]['port']
