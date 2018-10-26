import logging


def slots_manage(name, names_map, desired_slots):
    '''
    :param name: migrating node (hostname or pod name)
    :param names_map: { 'hostname1': {'ips': ["127.0.0.1"], 'port': 6379 }}
    :param desired_slots: {'hostname1': [1,2,3,4]}
    :return:
    '''
    ret = {'name': name,
           'result': False,
           'changes': {},
           'comment': ''}
    log = logging.getLogger(__name__)
    assigned_slots = {}
    actions = {}
    for name, details in names_map.items():
        #todo filter address by cidr, accept cidr as arg
        assigned_slots[name] = __salt__['redis_ext.slots'](details['ips'][0], details['port'])

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

    for node_name, action_map in actions.items():
        dest_ip = names_map[node_name]['ips'][0]
        dest_port = names_map[node_name]['port']
        changes_key = "destination node: {}".format(node_name)

        if __salt__['redis_ext.addslots'](dest_ip, dest_port, action_map['add']):
            ret['changes'][changes_key] = {
                'slots added': action_map['add']
            }

        for source_name, to_migrate in action_map['migrate'].items():
            src_ip = names_map[source_name]['ips'][0]
            src_port = names_map[source_name]['port']
            result = __salt__['redis_ext.migrate'](src_ip, src_port, dest_ip, dest_port, to_migrate)
            ret['changes'][changes_key].update({"slots migrated to this node": result})

    ret['result'] = True
    return ret
