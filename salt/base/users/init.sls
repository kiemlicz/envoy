include:
  - mounts
  - hosts
  - pkgs
{% if pillar.get('users', {}) %}
  - users.common
  - users.keys
  - users.tools
  - users.vpn
  - users.dotfiles
  - users.backup
{% else %}
empty-users-notification:
  test.show_notification:
    - name: No user configured
    - text: "No user was configured as none was specified"
{% endif %}
