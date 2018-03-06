{% from "lvs/map.jinja" import lvs with context %}

#include:
# -sls: keepalived

lvs_lb:
  pkg.installed:
    - name:

    #use lvs_service, does it assert kmod?


    #file managed file append - depending on keepalived existence