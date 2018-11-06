#queue them on the CLI, that would mean, reactor can do too
debug_orch:
  salt.state:
    - tgt: "k8s*"
    - subset: 1
    - sls:
        - debug
    - saltenv: {{ saltenv }}
