# Kubernetes
Deploys and configures the Kubernetes Nodes.  

## Available states
 - [`kubernetes.master`](https://github.com/kiemlicz/envoy/tree/master/salt/server/kubernetes#kubernetes.master)
 - [`kubernetes.worker`](https://github.com/kiemlicz/envoy/tree/master/salt/server/kubernetes#kubernetes.worker)
 - [`kubernetes.helm`](https://github.com/kiemlicz/envoy/tree/master/salt/server/kubernetes#kubernetes.helm)

## Usage
Some prerequisites must be met first:
 - minion config must contain:
```
use_superseded:
  - module.run
```

1. Set grains on minions that should represent workers and masters:
Masters:  
```
kubernetes:
    master: True
```
Workers:
```
kubernetes:
    worker: True
```
2. `salt-run state.orchestrate kubernetes._orchestrate.cluster saltenv=server`

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

### `kubernetes.helm`
Setup Kubernetes worker node

#### Example pillar

# Provisioning PODs
In this approach it is assumed that application images are already prepared. _Salt_ is used to orchestrate the application logic that would not be possible with Kubernetes tooling only. 
Kubernetes takes care of POD lifecycle management "only".  
Applications that require administrative work can still benefit from _Salt_.  
In order to leverage _Salt_ capabilities to orchestrate Kubernetes PODs following deployment strategies exists:  

_Salt Master_
 1. Deployed in separate VM outside of Kubernetes cluster.  
 2. Deployed in POD

_Salt Minion_
 1. Deployed as a _DaemonSet_ 
 2. Deployed directly on Kubernetes Nodes
 
| Minion\Master | Separate VM | POD |
| - | - | - |
| **DaemonSet** | The VM must be able to route traffic to k8s PODs. Minions must have k8s Node's `docker.sock` mounted | Minions must have Node's `docker.sock` mounted |
| **K8s Nodes** | Only k8s Nodes - VM connectivity must be possible. It must be possible to install _Salt Minion_ on k8s Nodes | Node-POD communication must be possible. It must be possible to install _Salt Minion_ on k8s Nodes | 


# References
1. https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
