# Kubernetes
Deploys and configures the Kubernetes Nodes.  

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

# Provisioning PODs
In order to leverage _Salt_ capabilities to orchestrate Kubernetes PODs following deployment strategies exists:  

_Salt Master_
 1. Deployed in separate VM outside of Kubernetes cluster.  
 2. Deployed in POD

_Salt Minion_
 1. Deployed as a _DaemonSet_ 
 2. Deployed directly on Kubernetes Nodes
 
| Minion \ Master | Separate VM | POD |
| - | - | - |
| DaemonSet | The VM must be able to route traffic to k8s PODs. Minions have Node's `docker.sock` mounted | Minions have Node's `docker.sock` mounted |
| K8s Nodes | Only k8s Nodes - VM connectivity must be possible. It must be possible to install _Salt Minion_ on k8s Nodes | Node-POD communication must be possible. It must be possible to install _Salt Minion_ on k8s Nodes | 


# References
1. https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/