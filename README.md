[![Build status](https://travis-ci.org/kiemlicz/envoy.svg?branch=master)](https://travis-ci.org/kiemlicz/envoy)
# Basics 
[Salt](https://saltstack.com/) _states_ for provisioning machines in generic yet sensible way.  
The goal is to create _salt environments_ usable by developers as well as admins during the setup of either server or 'client' machines.

## Setup  
There are multiple options to deploy **envoy**.  
They depend on how you want to provision machines:  
 1. Separate `salt-master` process provisioning `salt-minions`:  
Refer to SaltStack documentation of [gitfs](https://docs.saltstack.com/en/latest/topics/tutorials/gitfs.html) 
(if you prefer local filesystem then familiarize with [multienv](https://docs.saltstack.com/en/latest/ref/states/top.html)) or use 
fully automated setup of SaltStack via associated [project ambassador](https://github.com/kiemlicz/ambassador)

 2. Master-less provisioning (machine provisions itself):  
 **Steps**  
    1. `curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com`, requires (`apt-get install curl python-pip python-pygit2`)
    2. `sh /tmp/bootstrap-salt.sh stable # 2018.3.2`
    3. Use `config/common.conf` and `config/gitfs.conf` (put under `/etc/salt/minion.d/`)
    4. `systemctl restart salt-minion`  
    5. Optionally run `salt-call --local saltutil.sync_all`
  
### Using as Vagrant provisioner
Vagrant supports [_Salt_ provisioner](https://www.vagrantup.com/docs/provisioning/salt.html)

  1. Add proper sections to `Vagrantfile`.
```
    Vagrant.configure("2") do |config|
    ...
        config.vm.synced_folder "/srv/salt/", "/srv/salt/"  # add states from host
    
        config.vm.provision "init", type: "shell" do |s|
          s.path = "init.sh"
        end
    
        config.vm.provision :salt do |salt|
          salt.masterless = true
          salt.minion_config = "minion.conf"
          salt.run_highstate = true
          salt.salt_args = [ "saltenv=server" ]
        end
    ...
    end
```
    
`init.sh`: bash script that installs salt requisites, e.g., git, pip packages (jinja2) etc.  
`minion.conf`: configure `file_client: local` and whatever you like (mutlienvs, gitfs, ext_pillar)
  
  2. `vagrant up`
    
## Components
In order to run _states_ against _minions_, _pillar_ must be configured.  
Refer to `pillar.example.sls` files in states themselves for particular structure.  
_States_ must be written with assumption that given pillar entry may not exist.
For detailed state description, refer to particular states' README file.
 
# Structure
States are divided in environments:
 1. `base` - the main one. Any other environment comprises of at least `base`. Contains core states responsible for operations like
 repositories configuration, core packages installation or user setup
 2. `dev` - for developer machines. Includes `base`. Contains states that install tons of dev apps along with their configuration (like add entry to `PATH` variable)
 3. `server` - installs/configured typical server tools, e.g., kubernetes or LVS. Includes `base` and `dev`

# Extensions
In order to keep _states_ readable and configuration of whole SaltStack as flexible as possible, some extensions and custom states were introduced.

All of the custom states can be found in default _Salt_ extensions' [directories](https://docs.saltstack.com/en/latest/ref/file_server/dynamic-modules.html) (`_pillar`, `_runner`, etc.)

## pillar extensions
### privgit
Dynamically configured `ext_pillar`.  
Allows users to configure their own _pillar_ data git repository (in the runtime - using pillar entries)
Repository must contain pillar data under the `root` directory

#### Usage
Fully static configuration (use _git_pillar_ instead of such):
```
ext_pillar:
  - privgit:
    - name1:
      url: git@github.com:someone/somerepo.git
      branch: master  
      env: custom
      root: pillar
      privkey: |
      some
      sensitive data
      pubkey: and so on
    - name2:
      url: git@github.com:someone/somerepo.git
      branch: develop
      env: custom
      privkey_location: /location/on/master
      pubkey_location: /location/on/master
```
Each of such parameter can be overridden in _pillar_ data that comes before _ext_pillar_:
```
privgit:
  - name1:
    url: git@github.com:someone/somerepo.git
    branch: master  
    env: custom
    root: pillar
    privkey: |
    some
    sensitive data
    pubkey: and so on
  - name2:
    url: git@github.com:someone/somerepo.git
    branch: develop
    env: custom
    privkey_location: /location/on/master
    pubkey_location: /location/on/master
  - name2:
    url: git@github.com:someone/somerepo.git
    branch: notdevelop
```
Entries order does matter, last one is the most specific one. It doesn't affect further pillar merge strategies.
They rely on salt settings only

Due to potential integration with systems like [foreman](https://theforeman.org/) that support string keys only, 
another (unpleasant, flat) syntax exists:
```
privgit_name1_url: git@github.com:someone/somerepo.git
privgit_name1_branch: master 
privgit_name1_env: custom
privgit_name1_root: pillar
privgit_name1_privkey: |
        some
        sensitive data
privgit_name1_pubkey: and so on
privgit_name2_url: git@github.com:someone/somerepo.git
privgit_name2_branch: develop
privgit_name2_env: custom
privgit_name2_privkey_location: /location/on/master
privgit_name2_pubkey_location: /location/on/master
``` 

### kubectl
Pulls any kubernetes information and adds them to pillar.  
It is possible to specify pillar key under which the kubernetes data will be hooked up.  
Under the hood this extension executes:
`kubectl get -o yaml -n <namespace or deafult> <kind> <name>` or 
`kubectl get -o yaml -n <namespace or deafult> <kind> -l <selector>` if name is not provided
 
#### Usage
```
ext_pillar:
  - kubectl:
      config: "/some/path/to/kubernetes/access.conf"
      queries:
        - kind: statefulsets
          name: redis-cluster
          key: "redis:kubernetes"
``` 

## dotfile
Custom _state_ that manages [dotfiles](https://en.wikipedia.org/wiki/Dot-file).  
Clones them from passed repository and sets up according to following [technique](https://developer.atlassian.com/blog/2016/02/best-way-to-store-dotfiles-git-bare-repo/)
## devtool
Most dev tools setup comes down to downloading some kind of archive, unpacking it and possibly adding symlink to some generic location.  
This state does pretty much that.
## envops
Environment variables operations.
 
# References
1. SaltStack [quickstart](https://docs.saltstack.com/en/latest/topics/states/index.html)
2. SaltStack [best practices](https://docs.saltstack.com/en/latest/topics/best_practices.html)
