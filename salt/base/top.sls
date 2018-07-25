#!py


def run():
  def _merge(src, dst):
    for k, v in src.items():
      if isinstance(v, dict):
        _merge(v, dst.setdefault(k, {}))
      elif isinstance(v, list):
        dst.setdefault(k, []).extend(v)
      else:
        dst[k] = v
    return dst


  base = {
    '*': [
      "os",
      "samba",
      "mail",
    ],
    'G@os_family:Debian': [
      "os.pkgs.unattended"
    ],
    'not G@os:Windows and not G@virtual_subtype:Docker': [
      "lxc"
    ],
    'not G@os:Windows': [
      "users"
    ]
  }

  dev = {
    '*': [
      "java",
      "scala",
      "erlang",
      "gradle",
      "maven",
      "sbt",
      "rebar",
      "intellij",
      "robomongo",
      "grafana",
      "virtualbox",
      "projects",
      "influxdb",
      "redis.client",
      "mongodb.client",
    ],
    # Artful image has hard time whereas Debian does not: https://github.com/docker/for-linux/issues/230
    'not (G@virtual_subtype:Docker and G@oscodename:artful)': [
      "docker",
      "docker.compose",
    ],
    'I@redis:setup_type:cluster': [
      "redis.server.cluster"
    ],
    'I@redis:setup_type:single': [
      "redis.server.single"
    ],
    'I@mongodb:setup_type:cluster': [
      "mongodb.server.cluster"
    ],
    'I@mongodb:setup_type:single': [
      "mongodb.server.single"
    ]
  }

  server = {
    'not G@os:Windows': [
      "keepalived",
      "lvs.director",
      "lvs.realserver",
      "kvm"
    ]
  }

  top = {}
  top['base'] = base
  top['dev'] = _merge(base, dev)
  top['server'] = _merge(dev, server)
  return top
