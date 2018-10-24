setup_master:
  salt.state:
  - tgt: "kubernetes:master:True"
  - tgt_type: "grain"
  - saltenv: {{ saltenv }}
  - sls:
      - kubernetes.master

setup_workers:
  salt.state:
  - tgt: "kubernetes:worker:True"
  - tgt_type: "grain"
  - saltenv: {{ saltenv }}
  - sls:
    - kubernetes.worker
  - require:
      - salt: setup_master
