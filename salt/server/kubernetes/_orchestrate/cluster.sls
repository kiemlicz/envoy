setup_master:
  salt.state:
  - tgt: "kubernetes:master:True"
  - tgt_type: "grain"
  - saltenv: {{ saltenv }}
  - highstate: True

setup_workers:
  salt.state:
  - tgt: "kubernetes:worker:True"
  - tgt_type: "grain"
  - saltenv: {{ saltenv }}
  - highstate: True
  - require:
      - salt: setup_master
