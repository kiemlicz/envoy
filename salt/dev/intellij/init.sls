{% from "intellij/map.jinja" import intellij with context %}
{% from "_macros/dev_tool.macros.jinja" import link_to_bin with context %}

#todo must require window_manager

intellij:
  devtool.managed:
    - name: {{ intellij.generic_link }}
    - download_url: {{ intellij.download_url }}
    - destination_dir: {{ intellij.destination_dir }}
    - user: {{ intellij.owner }}
    - group: {{ intellij.owner }}
    - saltenv: {{ saltenv }}
{{ link_to_bin(intellij.owner_link_location, intellij.generic_link + '/bin/idea.sh', intellij.owner) }}
