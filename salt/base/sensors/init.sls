include:
  - pkgs

sensors:
  cmd.run:
    - name: yes YES | sensors-detect
    - require:
      - sls: pkgs
