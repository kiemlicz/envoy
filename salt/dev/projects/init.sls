include:
  - users
{% if pillar.get('users', {}) %}
  - projects.clone
{% else %}
empty-projects-notification:
  test.show_notification:
    - name: No user projects
    - text: "No user projects was configured as none was specified"
{% endif %}
