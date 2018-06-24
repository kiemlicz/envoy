{% from "kvm/map.jinja" import kvm with context %}


include:
  - os


kvm:
  pkg.latest:
    - name: kvm_packages
    - pkgs: {{ kvm.prerequisites }}
    - refresh: True
    - require:
      - sls: os
  group.present:
    - names: {{ kvm.groups }}
    - addusers: {{ kvm.users }}
