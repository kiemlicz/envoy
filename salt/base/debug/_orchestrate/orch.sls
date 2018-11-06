debug_orch:
  salt.state:
    - tgt: "k8s*"
#    - subset: 1
    #- queue: True
    - batch: 1
    - sls:
        - debug
    - saltenv: {{ saltenv }}
