start:
  cmd.run:
    - name: "date >> /tmp/dates"

long_state:
  cmd.run:
    - name: "sleep 30"
    - require:
        - cmd: start
end:
  cmd.run:
    - name: "date >> /tmp/dates"
    - require:
        - cmd: long_state
