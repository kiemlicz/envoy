{% set event = 'salt/orchestrate/redis/start' %}

redis_count:
  reg_ext.last:
    - add: instances_count
    - match: {{ event }}
    - prune: 1
redis_ready:
  reg.list:
    - add: instance
    - match: {{ event }}


redis_instances:
  check.len_eq_reg:
    - name: redis_ready
    - len_reg: redis_count
    - len_reg_val: instances_count

redis_orchestrate:
  reg.delete:
    - name: redis_count
    - require:
      - check: redis_instances
  runner.cmd:
    - func: event.send
    - arg:
        - salt/orchestrate/redis/ready
    - require:
      - reg: redis_orchestrate
