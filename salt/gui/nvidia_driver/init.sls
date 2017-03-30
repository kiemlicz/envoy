{% from "nvidia_driver/map.jinja" import nvidia with context %}
# todo blacklist nouveau before installing (use blacklisting conf supplied)
# install headers aptitude install linux-headers-$(uname -r|sed 's,[^-]*-[^-]*-,,')
# add laptop support
nvidia_driver:
  service.dead:
    - names: {{ nvidia.dependent_services }}
  kmod.absent:
    - mods: {{ nvidia.dependent_kernel_modules }}
  cmd.script:
    - source: {{ nvidia.driver_url }}
    - args: "--update -a --dkms -X -Z -f --opengl-headers --no-questions -s"
    - require_in:
      - sls: pkgs
