# Kubernetes management
Run salt-minion on kubernetes nodes  
Capture and react for docker events

# Usage
Setup `top.sls` so that it matches your infrastructure and contains `docker` states also.  
Example (using grain targeting):  

```
server:
  'kubernetes:master:True':
  - match: grain
  - os
  - docker
  - docker.events
  - kubernetes.master
  'kubernetes:worker:True':
  - match: grain
  - os
  - docker
  - docker.events
  - kubernetes.worker
```
Then run:  
`salt-run state.orchestrate kubernetes._orchestrate.cluster saltenv=server`
