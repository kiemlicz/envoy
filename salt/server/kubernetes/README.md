# Kubernetes
Configures kubernetes nodes.  

## Available states
 - [`kubernetes.master`](https://github.com/kiemlicz/envoy/tree/master/salt/server/kubernetes#kubernetes.master)
 - [`kubernetes.worker`](https://github.com/kiemlicz/envoy/tree/master/salt/server/kubernetes#kubernetes.worker)

### `kubernetes.master`
Setup Kubernetes master node

#### Example pillar
```
kubernetes:
  network:
    provider: flannel
    cidr: "10.244.0.0/16"
  master:
    isolate: True
    reset: False          # whether issue kubeadm reset beforehand 
    upload_config: True   # whether to push config file to salt-master
```

### `kubernetes.worker`
Setup Kubernetes worker node

#### Example pillar

## Example
Setup `top.sls` so that it matches your infrastructure and contains `docker` states also.  
Using grain targeting:  

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

# References
1. https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/