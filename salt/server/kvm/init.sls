{% from "kvm/map.jinja" import kvm with context %}


include:
  - pkgs


kvm:
  pkg.latest:
    - name: kvm_packages
    - pkgs: {{ kvm.prerequisites }}
    - refresh: True
    - require:
      - pkg: os_packages
  group.present:
    - names: {{ kvm.groups }}
    - addusers: {{ kvm.users }}
