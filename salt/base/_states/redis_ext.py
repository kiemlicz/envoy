import logging


def slots_manage(name, names_map, desired_slots, cidr=None):
    '''
    :param name: migrating node (hostname or pod name)
    :param names_map: { 'hostname1': {'ips': ["127.0.0.1"], 'port': 6379 }}
    :param desired_slots: {'hostname1': [1,2,3,4]}
    :param cidr: 192.168.1.0/24 mutliple addresses optional filter
    :return:
    '''
    ret = {'name': name,
           'result': False,
           'changes': {},
           'comment': ''}
    log = logging.getLogger(__name__)

    def filter_ip(ips):
        if cidr:
            return [e for e in ips if __salt__['network.ip_in_subnet'](e, cidr)]
        else:
            return ips

    assigned_slots = {}
    actions = {}
    for name, details in names_map.items():
        ip = filter_ip(details['ips'])[0]
        port = details['port']
        log.debug("Finding current slot assignmet for {}:{} (name: {})".format(ip, port, name))
        assigned_slots[name] = __salt__['redis_ext.slots'](ip, port)

    log.info("Current slots assignment: {}".format(assigned_slots))
    log.info("Desired slots assignment: {}".format(desired_slots))

    for node_name, desired_slot_list in desired_slots.items():
        add = set(desired_slot_list) - set(assigned_slots[node_name])
        migrate_map = {}
        for other_node in [e for e in assigned_slots.keys() if e != node_name]:
            to_migrate = set(assigned_slots[other_node]) & set(add)
            if len(to_migrate) != 0:
                migrate_map[other_node] = to_migrate
                add = add - to_migrate
        actions[node_name] = {
            'add': add,
            'migrate': migrate_map
        }

    log.info("Computed actions: {}".format(actions))

    for node_name, action_map in actions.items():
        dest_ip = filter_ip(names_map[node_name]['ips'])[0]
        dest_port = names_map[node_name]['port']
        changes_key = "destination node: {}".format(node_name)

        if __salt__['redis_ext.addslots'](dest_ip, dest_port, action_map['add']):
            log.debug("Added slots to {}:{}".format(dest_ip, dest_port))
            ret['changes'][changes_key] = {
                'slots added': action_map['add']
            }
        else:
            log.error("Unable to add slots to: {}:{}".format(dest_ip, dest_port))
            ret['changes'][changes_key] = {
                'slots added': "Failed. Wanted to add: {}".format(action_map['add'])
            }
            return ret

        for source_name, to_migrate in action_map['migrate'].items():
            src_ip = filter_ip(names_map[source_name]['ips'])[0]
            src_port = names_map[source_name]['port']
            result = __salt__['redis_ext.migrate'](src_ip, src_port, dest_ip, dest_port, to_migrate)
            log.debug("Migrating slots from {}:{} to {}:{}".format(src_ip, src_port, dest_ip, dest_port))
            ret['changes'][changes_key].update({"slots migrated to this node": result})
            if not result['result']:
                log.error("Failed to migrate slots ({}:{} -> {}:{})".format(src_ip, src_port, dest_ip, dest_port))
                ret['changes'][changes_key].update({"slots migrated to this node": result})
                return ret

    ret['result'] = True
    return ret
